defmodule Persist.Load.BroadwayTest do
  use ExUnit.Case
  import Mox
  require Temp.Env
  import AssertAsync

  alias Writer.DLQ.DeadLetter
  @moduletag capture_log: true

  Temp.Env.modify([
    %{
      app: :service_persist,
      key: Persist.Load.Broadway,
      update: fn config ->
        Keyword.put(config, :dlq, Persist.DLQMock)
      end
    }
  ])

  setup do
    Process.flag(:trap_exit, true)
    :ok
  end

  setup :set_mox_global
  setup :verify_on_exit!

  test "will decode message and pass to writer" do
    test = self()

    load =
      Load.Persist.new!(
        id: "load-1",
        dataset_id: "ds1",
        name: "fake-name",
        source: "topic-a",
        destination: "table-a",
        schema: [
          %Dictionary.Type.String{name: "name"},
          %Dictionary.Type.Integer{name: "age"}
        ]
      )

    writer = fn msgs ->
      send(test, {:write, msgs})
      :ok
    end

    {:ok, broadway} = Persist.Load.Broadway.start_link(load: load, writer: writer)

    messages = [
      %{value: %{"name" => "bob", "age" => 21} |> Jason.encode!()},
      %{value: %{"name" => "joe", "age" => 43} |> Jason.encode!()}
    ]

    ref = Broadway.test_messages(broadway, messages)

    expected = [
      %{"name" => "bob", "age" => 21},
      %{"name" => "joe", "age" => 43}
    ]

    assert_receive {:write, ^expected}

    assert_receive {:ack, ^ref, successful, []}
    assert 2 == length(successful)
    assert_down(broadway)
  end

  test "will normalize message before sending to writer" do
    test = self()

    load =
      Load.Persist.new!(
        id: "load-1",
        dataset_id: "ds1",
        name: "fake-name",
        source: "topic-a",
        destination: "table-a",
        schema: [
          %Dictionary.Type.String{name: "name"},
          %Dictionary.Type.Integer{name: "age"}
        ]
      )

    writer = fn msgs ->
      send(test, {:write, msgs})
      :ok
    end

    {:ok, broadway} = Persist.Load.Broadway.start_link(load: load, writer: writer)

    messages = [
      %{value: %{"name" => "bob", "age" => "21"} |> Jason.encode!()},
      %{value: %{"name" => "joe", "age" => "43"} |> Jason.encode!()}
    ]

    Broadway.test_messages(broadway, messages)

    expected = [
      %{"name" => "bob", "age" => 21},
      %{"name" => "joe", "age" => 43}
    ]

    assert_receive {:write, ^expected}
    assert_down(broadway)
  end

  test "sends message to dlq if it fails to decode" do
    test = self()

    load =
      Load.Persist.new!(
        id: "load-1",
        dataset_id: "ds1",
        name: "fake-name",
        source: "topic-c",
        destination: "table-a",
        schema: [
          %Dictionary.Type.String{name: "name"},
          %Dictionary.Type.Integer{name: "age"}
        ]
      )

    writer = fn msgs ->
      send(test, {:write, msgs})
      :ok
    end

    Persist.DLQMock
    |> expect(:write, fn messages ->
      send(test, {:dlq, messages})
      :ok
    end)

    {:ok, broadway} = Persist.Load.Broadway.start_link(load: load, writer: writer)

    messages = [
      %{value: %{"name" => "bob", "age" => 21} |> Jason.encode!()},
      %{value: "{\"one\""}
    ]

    ref = Broadway.test_messages(broadway, messages)

    {:error, reason} = messages |> Enum.at(1) |> Map.get(:value) |> Jason.decode()

    expected_dead_letter =
      DeadLetter.new(
        dataset_id: "ds1",
        original_message: Enum.at(messages, 1),
        app_name: "service_persist",
        reason: reason
      )

    assert_receive {:write, [%{"name" => "bob", "age" => 21}]}
    assert_receive {:dlq, [^expected_dead_letter]}

    assert_receive {:ack, ^ref, [%{data: %{"name" => "bob", "age" => 21}}], []}
    assert_receive {:ack, ^ref, [], [%{data: ^expected_dead_letter}]}
    assert_down(broadway)
  end

  test "sends to dlq if message fails normalization" do
    test = self()

    load =
      Load.Persist.new!(
        id: "load-1",
        dataset_id: "ds1",
        name: "fake-name",
        source: "topic-c",
        destination: "table-a",
        schema: [
          %Dictionary.Type.String{name: "name"},
          %Dictionary.Type.Integer{name: "age"}
        ]
      )

    writer = fn msgs ->
      send(test, {:write, msgs})
      :ok
    end

    Persist.DLQMock
    |> expect(:write, fn messages ->
      send(test, {:dlq, messages})
      :ok
    end)

    {:ok, broadway} = Persist.Load.Broadway.start_link(load: load, writer: writer)

    messages = [
      %{value: %{"name" => "bob", "age" => 21} |> Jason.encode!()},
      %{value: %{"name" => "sally", "age" => "twenty-two"} |> Jason.encode!()}
    ]

    Broadway.test_messages(broadway, messages)

    reason = %{"age" => :invalid_integer}

    expected_dead_letter =
      DeadLetter.new(
        dataset_id: "ds1",
        original_message: Enum.at(messages, 1),
        app_name: "service_persist",
        reason: reason
      )

    assert_receive {:write, [%{"name" => "bob", "age" => 21}]}
    assert_receive {:dlq, [^expected_dead_letter]}
    assert_down(broadway)
  end

  defp assert_down(pid) do
    Process.exit(pid, :normal)
    assert_receive {:EXIT, ^pid, _}, 10_000

    assert_async do
      assert [] == Persist.Load.Registry.registered_processes()
    end
  end
end

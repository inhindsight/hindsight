defmodule Persist.Load.BroadwayTest do
  use ExUnit.Case
  use Placebo
  import Mox
  require Temp.Env

  alias Writer.DLQ.DeadLetter
  @moduletag capture_log: true

  Temp.Env.modify([
    %{
      app: :service_persist,
      key: Persist.Load.Broadway,
      update: fn config ->
        Keyword.put(config, :dlq, Persist.DLQMock)
        |> Keyword.put(:configuration, BroadwayConfigurator.Dummy)
      end
    }
  ])

  setup do
    Process.flag(:trap_exit, true)

    transform =
      Transform.new!(
        id: "transform-1",
        dataset_id: "ds1",
        subset_id: "sb1",
        dictionary: [
          %Dictionary.Type.String{name: "name"},
          %Dictionary.Type.Integer{name: "age"}
        ],
        steps: [
          Transform.MoveField.new!(from: "name", to: "fullname")
        ]
      )

    load =
      Load.Persist.new!(
        id: "load-1",
        dataset_id: "ds1",
        subset_id: "fake-name",
        source: "topic-a",
        destination: "table-a"
      )

    [load: load, transform: transform]
  end

  setup :set_mox_global
  setup :verify_on_exit!

  test "will decode message and pass to writer", %{load: load, transform: transform} do
    test = self()

    writer = fn msgs ->
      send(test, {:write, msgs})
      :ok
    end

    {:ok, broadway} =
      start_supervised({Persist.Load.Broadway, load: load, transform: transform, writer: writer})

    messages = [
      %{value: %{"name" => "bob", "age" => 21} |> Jason.encode!()},
      %{value: %{"name" => "joe", "age" => 43} |> Jason.encode!()}
    ]

    ref = Broadway.test_messages(broadway, messages)

    expected = [
      %{"fullname" => "bob", "age" => 21},
      %{"fullname" => "joe", "age" => 43}
    ]

    assert_receive {:write, ^expected}

    assert_receive {:ack, ^ref, successful, []}
    assert 2 == length(successful)
  end

  test "sends message to dlq if it fails to decode", %{load: load, transform: transform} do
    test = self()

    writer = fn msgs ->
      send(test, {:write, msgs})
      :ok
    end

    Persist.DLQMock
    |> stub(:write, fn messages ->
      send(test, {:dlq, messages})
      :ok
    end)

    {:ok, broadway} =
      start_supervised({Persist.Load.Broadway, load: load, transform: transform, writer: writer})

    messages = [
      %{value: %{"name" => "bob", "age" => 21} |> Jason.encode!()},
      %{value: "{\"one\""}
    ]

    ref = Broadway.test_messages(broadway, messages)

    {:error, reason} = messages |> Enum.at(1) |> Map.get(:value) |> Jason.decode()

    expected_dead_letter =
      DeadLetter.new(
        dataset_id: "ds1",
        subset_id: "fake-name",
        original_message: Enum.at(messages, 1),
        app_name: "service_persist",
        reason: reason
      )
      |> Map.merge(%{stacktrace: nil, timestamp: nil})

    assert_receive {:write, [%{"fullname" => "bob", "age" => 21}]}
    assert_receive {:dlq, [actual_dead_letter]}, 2_000

    assert expected_dead_letter ==
             actual_dead_letter |> Map.merge(%{stacktrace: nil, timestamp: nil})

    assert_receive {:ack, ^ref, [%{data: %{"fullname" => "bob", "age" => 21}}], []}
    assert_receive {:ack, ^ref, [], [%{data: %{value: "{\"one\""}}]}
  end

  test "sends to dlq if exception is raised while processing message", %{
    load: load,
    transform: transform
  } do
    test = self()

    writer = fn _msgs ->
      raise "something terrible happened"
    end

    Persist.DLQMock
    |> expect(:write, fn messages ->
      send(test, {:dlq, messages})
      :ok
    end)

    {:ok, broadway} =
      start_supervised({Persist.Load.Broadway, load: load, transform: transform, writer: writer})

    messages = [
      %{value: %{"name" => "bob", "age" => 21} |> Jason.encode!()}
    ]

    ref = Broadway.test_messages(broadway, messages)

    assert_receive {:dlq, [dead_letter]}
    assert dead_letter.dataset_id == "ds1"
    assert dead_letter.subset_id == "fake-name"
    assert dead_letter.original_message == %{"fullname" => "bob", "age" => 21}
    assert dead_letter.reason =~ "something terrible happened"
    assert_receive {:ack, ^ref, [], _}
  end
end

defmodule Persist.Load.BroadwayTest do
  use ExUnit.Case
  import Mox

  alias Writer.DLQ.DeadLetter
  @moduletag capture_log: true

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

    Persist.WriterMock
    |> expect(:start_link, fn init_arg ->
      send(test, {:start_link, init_arg})
      {:ok, :writer_pid}
    end)
    |> expect(:write, fn server, messages ->
      send(test, {:write, server, messages})
      :ok
    end)

    {:ok, broadway} = Persist.Load.Broadway.start_link(load: load)
    on_exit(fn -> assert_down(broadway) end)

    messages = [
      %{value: %{"name" => "bob", "age" => 21} |> Jason.encode!()},
      %{value: %{"name" => "joe", "age" => 43} |> Jason.encode!()}
    ]

    ref = Broadway.test_messages(broadway, messages)

    expected = [
      %{"name" => "bob", "age" => 21},
      %{"name" => "joe", "age" => 43}
    ]

    assert_receive {:write, :writer_pid, ^expected}

    assert_receive {:ack, ^ref, successful, []}
    assert 2 == length(successful)
  end

  test "broadway registers itself with the Persist.Load.Registry" do
    load =
      Load.Persist.new!(
        id: "load-1",
        dataset_id: "ds1",
        name: "fake-name",
        source: "topic-b",
        destination: "table-a",
        schema: [
          %Dictionary.Type.String{name: "name"},
          %Dictionary.Type.Integer{name: "age"}
        ]
      )

    Persist.WriterMock
    |> expect(:start_link, fn _init_arg ->
      {:ok, :writer_pid}
    end)

    {:ok, pid} = Persist.Load.Broadway.start_link(load: load)
    on_exit(fn -> assert_down(pid) end)

    assert pid == Persist.Load.Registry.whereis(:"#{load.source}")
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

    Persist.WriterMock
    |> expect(:start_link, fn init_arg ->
      send(test, {:start_link, init_arg})
      {:ok, :writer_pid}
    end)
    |> expect(:write, fn server, messages ->
      send(test, {:write, server, messages})
      :ok
    end)

    Persist.DLQMock
    |> expect(:write, fn messages ->
      send(test, {:dlq, messages})
      :ok
    end)

    {:ok, broadway} = Persist.Load.Broadway.start_link(load: load)
    on_exit(fn -> assert_down(broadway) end)

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
        app_name: Application.get_env(:service_persist, :app_name),
        reason: reason
      )

    assert_receive {:write, :writer_pid, [%{"name" => "bob", "age" => 21}]}
    assert_receive {:dlq, [^expected_dead_letter]}

    assert_receive {:ack, ^ref, [%{data: %{"name" => "bob", "age" => 21}}], []}
    assert_receive {:ack, ^ref, [], [%{data: ^expected_dead_letter}]}
  end

  defp assert_down(pid) do
    ref = Process.monitor(pid)
    Process.exit(pid, :kill)
    assert_receive {:DOWN, ^ref, _, _, _}
  end
end

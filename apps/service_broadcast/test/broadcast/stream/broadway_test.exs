defmodule Broadcast.Stream.BroadwayTest do
  use BroadcastWeb.ChannelCase
  import Mox
  require Temp.Env

  alias Writer.DLQ.DeadLetter

  @instance Broadcast.Application.instance()

  Temp.Env.modify([
    %{
      app: :service_broadcast,
      key: Broadcast.Stream.Broadway,
      update: fn config ->
        Keyword.put(config, :dlq, Broadcast.DLQMock)
      end
    }
  ])

  setup :set_mox_global
  setup :verify_on_exit!

  setup do
    Process.flag(:trap_exit, true)
    Brook.Test.clear_view_state(@instance, "transformations")
    test = self()

    Broadcast.DLQMock
    |> stub(:write, fn msgs ->
      send(test, {:dlq, msgs})
    end)

    :ok
  end

  test "sends message to channel" do
    load =
      Load.Broadcast.new!(
        id: "load-1",
        dataset_id: "ds1",
        name: "fake-ds",
        source: "topic-1",
        destination: "channel-1"
      )

    {:ok, _, socket} =
      socket(BroadcastWeb.UserSocket, %{}, %{})
      |> subscribe_and_join(BroadcastWeb.Channel, "broadcast:channel-1", %{})

    {:ok, pid} = Broadcast.Stream.Broadway.start_link(load: load)

    value = %{"one" => 1} |> Jason.encode!()
    message = %{topic: "topic-1", value: value}
    msg_ref = Broadway.test_messages(pid, [message])

    assert_push "update", %{"one" => 1}, 2_000
    assert_receive {:ack, ^msg_ref, [message] = _successful, _failed}, 1_000

    assert_down(pid)
    leave(socket)
  end

  test "transforms message before sending it to channel" do
    transform = Transform.new!(
      id: "transform-1",
      dataset_id: "ds1",
      dictionary: [
        Dictionary.Type.String.new!(name: "name"),
        Dictionary.Type.Integer.new!(name: "age")
      ],
      steps: [
        Transform.RenameField.new!(from: "name", to: "fullname")
      ]
    )

    Brook.Test.with_event(@instance, fn ->
      Broadcast.Transformations.persist(transform)
    end)

    load =
      Load.Broadcast.new!(
        id: "load-1",
        dataset_id: "ds1",
        name: "fake-ds",
        source: "topic-1",
        destination: "channel-2"
      )

    {:ok, _, socket} =
      socket(BroadcastWeb.UserSocket, %{}, %{})
      |> subscribe_and_join(BroadcastWeb.Channel, "broadcast:channel-2", %{})

    {:ok, pid} = Broadcast.Stream.Broadway.start_link(load: load)

    value = %{"name" => "Johnny Appleseed", "age" => 110} |> Jason.encode!()
    message = %{topic: "topic-1", value: value}
    msg_ref = Broadway.test_messages(pid, [message])

    assert_push "update", %{"fullname" => "Johnny Appleseed", "age" => 110}, 2_000
    assert_receive {:ack, ^msg_ref, [message] = _successful, _failed}, 1_000

    assert_down(pid)
    leave(socket)
  end

  test "fails message if unable to decode" do
    load =
      Load.Broadcast.new!(
        id: "load-1",
        dataset_id: "ds1",
        name: "fake-ds",
        source: "topic-2",
        destination: "channel-2"
      )

    {:ok, pid} = Broadcast.Stream.Broadway.start_link(load: load)

    value = "{\"one\""
    message = %{topic: "topic-2", value: value}
    msg_ref = Broadway.test_messages(pid, [message])

    {:error, reason} = Jason.decode(value)

    expected_dead_letter =
      DeadLetter.new(
        dataset_id: "ds1",
        original_message: message,
        app_name: "service_broadcast",
        reason: reason
      )

    assert_receive {:dlq, [^expected_dead_letter]}
    assert_receive {:ack, ^msg_ref, _successful, [message] = _failed}

    assert_down(pid)
  end

  test "registers itself under under source" do
    load =
      Load.Broadcast.new!(
        id: "load-id",
        dataset_id: "ds1",
        name: "joey",
        source: "topic-3",
        destination: "channel-3"
      )

    {:ok, pid} = Broadcast.Stream.Broadway.start_link(load: load)
    assert pid == Broadcast.Stream.Registry.whereis(:"topic-3")

    assert_down(pid)
  end

  test "start-link returns error tuple if unable to create transformer" do
    transform = Transform.new!(
      id: "transform-1",
      dataset_id: "ds1",
      dictionary: [
        Dictionary.Type.String.new!(name: "name"),
        Dictionary.Type.Integer.new!(name: "age")
      ],
      steps: [
        %Transform.Test.Steps.Error{error: "failed"}
      ]
    )

    Brook.Test.with_event(@instance, fn ->
      Broadcast.Transformations.persist(transform)
    end)

    load =
      Load.Broadcast.new!(
        id: "load-1",
        dataset_id: "ds1",
        name: "fake-ds",
        source: "topic-1",
        destination: "channel-2"
      )

    assert {:error, "failed"} == Broadcast.Stream.Broadway.start_link(load: load)
  end

  defp assert_down(pid) do
    ref = Process.monitor(pid)
    Process.exit(pid, :normal)
    assert_receive {:DOWN, ^ref, _, _, _}
  end
end

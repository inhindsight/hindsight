defmodule Broadcast.Stream.BroadwayTest do
  use BroadcastWeb.ChannelCase

  test "sends message to channel" do
    load = %Broadcast.Load{
      id: "load-1",
      dataset_id: "ds1",
      name: "fake-ds"
    }

    {:ok, _, socket} =
      socket(BroadcastWeb.UserSocket, %{}, %{})
      |> subscribe_and_join(BroadcastWeb.Channel, "broadcast:topic-1", %{})

    {:ok, pid} = Broadcast.Stream.Broadway.start_link(load: load)

    value = %{"one" => 1} |> Jason.encode!()
    message = %{topic: "topic-1", value: value}
    msg_ref = Broadway.test_messages(pid, [message])

    assert_push "update", %{"one" => 1}, 2_000
    assert_receive {:ack, ^msg_ref, [message] = _successful, _failed}, 1_000

    assert_down(pid)
    leave(socket)
  end

  test "fails message if unable to decode" do
    load = %Broadcast.Load{
      id: "load-1",
      dataset_id: "ds1",
      name: "fake-ds"
    }

    {:ok, pid} = Broadcast.Stream.Broadway.start_link(load: load)

    value = "{\"one\""
    message = %{topic: "topic-2", value: value}
    msg_ref = Broadway.test_messages(pid, [message])

    assert_receive {:ack, ^msg_ref, _successful, [message] = _failed}

    assert_down(pid)
  end

  test "registers itself under dataset_id and name" do
    load = %Broadcast.Load{
      id: "load-id",
      dataset_id: "ds1",
      name: "joey"
    }

    {:ok, pid} = Broadcast.Stream.Broadway.start_link(load: load)
    assert pid == Broadcast.Stream.Registry.whereis(:ds1_joey)

    assert_down(pid)
  end

  defp assert_down(pid) do
    ref = Process.monitor(pid)
    Process.exit(pid, :normal)
    assert_receive {:DOWN, ^ref, _, _, _}
  end
end

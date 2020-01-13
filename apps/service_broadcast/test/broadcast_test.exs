defmodule BroadcastTest do
  use BroadcastWeb.ChannelCase
  import AssertAsync

  import Definition.Events, only: [load_stream_start: 0, load_stream_end: 0]

  @instance Broadcast.Application.instance()

  test "sending #{load_stream_start()} will stream data to channel" do
    load = %Load.Broadcast{
      id: "load-1",
      dataset_id: "ds1",
      name: "intersections"
    }

    {:ok, _, socket} =
      socket(BroadcastWeb.UserSocket, %{}, %{})
      |> subscribe_and_join(BroadcastWeb.Channel, "broadcast:ds1_intersections", %{})

    Brook.Test.send(@instance, load_stream_start(), "testing", load)

    assert_async do
      :undefined != Broadcast.Stream.Registry.whereis(:ds1_intersections)
    end

    broadway_pid = Broadcast.Stream.Registry.whereis(:ds1_intersections)

    value = %{"one" => 1, "two" => 2} |> Jason.encode!()
    message = %{topic: "ds1_intersections", value: value}
    Broadway.test_messages(broadway_pid, [message])

    assert_push "update", %{"one" => 1, "two" => 2}
    assert load == Broadcast.Stream.Store.get!("load-1")

    Brook.Test.send(@instance, load_stream_end(), "testing", load)

    assert_async do
      assert Process.alive?(broadway_pid) == false
    end

    assert nil == Broadcast.Stream.Store.get!("load-1")

    leave(socket)
  end
end

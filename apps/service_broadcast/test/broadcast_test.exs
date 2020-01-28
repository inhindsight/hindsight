defmodule BroadcastTest do
  use BroadcastWeb.ChannelCase
  import AssertAsync

  import Events, only: [load_broadcast_start: 0, load_broadcast_end: 0]

  @instance Broadcast.Application.instance()

  setup do
    Brook.Test.clear_view_state(@instance, "transformations")

    :ok
  end

  test "sending #{load_broadcast_start()} will stream data to channel" do
    load =
      Load.Broadcast.new!(
        id: "load-1",
        dataset_id: "ds1",
        name: "intersections",
        source: "topic-intersections",
        destination: "ds1_intersections"
      )

    {:ok, _, socket} =
      socket(BroadcastWeb.UserSocket, %{}, %{})
      |> subscribe_and_join(BroadcastWeb.Channel, "broadcast:ds1_intersections", %{})

    Brook.Test.send(@instance, load_broadcast_start(), "testing", load)

    assert_async do
      assert :undefined != Broadcast.Stream.Registry.whereis(:"topic-intersections")
    end

    broadway_pid = Broadcast.Stream.Registry.whereis(:"topic-intersections")

    value = %{"one" => 1, "two" => 2} |> Jason.encode!()
    message = %{topic: "topic_intersections", value: value}
    Broadway.test_messages(broadway_pid, [message])

    assert_push "update", %{"one" => 1, "two" => 2}
    assert load == Broadcast.Stream.Store.get!("load-1")

    Brook.Test.send(@instance, load_broadcast_end(), "testing", load)

    assert_async do
      assert Process.alive?(broadway_pid) == false
    end

    assert nil == Broadcast.Stream.Store.get!("load-1")

    leave(socket)
  end
end

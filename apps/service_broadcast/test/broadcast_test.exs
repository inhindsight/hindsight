defmodule BroadcastTest do
  use BroadcastWeb.ChannelCase
  import AssertAsync

  import Events, only: [load_broadcast_start: 0, load_broadcast_end: 0]
  import Definition, only: [identifier: 1]

  @instance Broadcast.Application.instance()

  setup do
    Brook.Test.clear_view_state(@instance, "transformations")

    Brook.Test.with_event(@instance, fn ->
      Broadcast.Transformations.persist(
        Transform.new!(
          id: "transform-1",
          dataset_id: "ds1",
          subset_id: "intersections",
          dictionary: [
            Dictionary.Type.Integer.new!(name: "one"),
            Dictionary.Type.Integer.new!(name: "two")
          ],
          steps: [
            Transform.MoveField.new!(from: ["one"], to: ["three"])
          ]
        )
      )
    end)

    load =
      Load.Broadcast.new!(
        id: "load-1",
        dataset_id: "ds1",
        subset_id: "intersections",
        source: Source.Fake.new(),
        destination: "ds1_intersections",
        cache: 200
      )

    [load: load]
  end

  test "sending #{load_broadcast_start()} will stream data to channel", %{load: load} do
    {:ok, _, socket} =
      socket(BroadcastWeb.UserSocket, %{}, %{})
      |> subscribe_and_join(BroadcastWeb.Channel, "broadcast:ds1_intersections", %{})

    Brook.Test.send(@instance, load_broadcast_start(), "testing", load)

    assert_async do
      assert :undefined != Broadcast.Stream.Registry.whereis(identifier(load))
    end

    assert_receive {:source_start_link, _, _}, 2_000

    value = %{"one" => 1, "two" => 2}
    Source.Fake.inject_messages(load.source, [value])

    assert_push "update", %{"three" => 1, "two" => 2}
    assert load == Broadcast.Stream.Store.get!(load.dataset_id, load.subset_id)
    cache = Broadcast.Cache.Registry.via(identifier(load))
    assert [%{"three" => 1, "two" => 2}] == Broadcast.Cache.get(cache)

    Brook.Test.send(@instance, load_broadcast_end(), "testing", load)

    assert_async do
      assert :undefined == Broadcast.Stream.Registry.whereis(identifier(load))
    end

    Broadcast.Stream.Store.done?(load)

    leave(socket)
  end

  test "joining a channel will send all the cached data", %{load: load} do
    cache = Broadcast.Cache.Registry.via("cache_join")
    {:ok, pid} = Broadcast.Cache.start_link(name: cache, load: load)

    Broadcast.Cache.add(pid, [%{"one" => 1}, %{"two" => 2}])

    {:ok, _, socket} =
      socket(BroadcastWeb.UserSocket, %{}, %{})
      |> subscribe_and_join(BroadcastWeb.Channel, "broadcast:cache_join", %{})

    assert_push "update", %{"one" => 1}
    assert_push "update", %{"two" => 2}

    leave(socket)
  end
end

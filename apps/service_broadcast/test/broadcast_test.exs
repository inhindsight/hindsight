defmodule BroadcastTest do
  use BroadcastWeb.ChannelCase
  import AssertAsync

  import Events, only: [load_start: 0, load_end: 0]
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
      Load.new!(
        id: "load-1",
        dataset_id: "ds1",
        subset_id: "intersections",
        source: Source.Fake.new!(),
        destination: Channel.Topic.new!(name: "ds1_intersections", cache: 200)
      )

    [load: load]
  end

  test "sending #{load_start()} will stream data to channel", %{load: load} do
    {:ok, _, socket} =
      socket(BroadcastWeb.UserSocket, %{}, %{})
      |> subscribe_and_join(BroadcastWeb.Channel, "broadcast:ds1_intersections", %{})

    Brook.Test.send(@instance, load_start(), "testing", load)

    assert_async do
      assert :undefined != Broadcast.Stream.Registry.whereis(identifier(load))
    end

    assert_receive {:source_start_link, _, _}, 2_000

    value = %{"one" => 1, "two" => 2}
    Source.Fake.inject_messages(load.source, [value])

    assert_push "update", %{"three" => 1, "two" => 2}
    assert load == Broadcast.Stream.Store.get!(load.dataset_id, load.subset_id)

    Brook.Test.send(@instance, load_end(), "testing", load)

    assert_async do
      assert :undefined == Broadcast.Stream.Registry.whereis(identifier(load))
    end

    Broadcast.Stream.Store.done?(load)

    leave(socket)
  end

  test "will send any cached messages to client upon connection", %{load: load} do
    Brook.Test.send(@instance, load_start(), "testing", load)

    assert_async do
      assert :undefined != Broadcast.Stream.Registry.whereis(identifier(load))
    end

    assert_receive {:source_start_link, _, _}, 2_000

    value = %{"one" => 1, "two" => 2}
    Source.Fake.inject_messages(load.source, [value])

    assert_async do
      cache = Broadcast.Cache.Registry.via(load.destination.name)
      assert [%{"three" => 1, "two" => 2}] == Broadcast.Cache.get(cache)
    end

    {:ok, _, socket} =
      socket(BroadcastWeb.UserSocket, %{}, %{})
      |> subscribe_and_join(BroadcastWeb.Channel, "broadcast:ds1_intersections", %{})

    assert_push "update", %{"three" => 1, "two" => 2}, 5_000

    Brook.Test.send(@instance, load_end(), "testing", load)

    assert_async do
      assert :undefined == Broadcast.Stream.Registry.whereis(load.destination.name)
    end

    Broadcast.Stream.Store.done?(load)

    leave(socket)
  end
end

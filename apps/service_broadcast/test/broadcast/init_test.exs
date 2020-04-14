defmodule Broadcast.InitTest do
  use ExUnit.Case
  use Placebo
  import AssertAsync

  @instance Broadcast.Application.instance()

  setup do
    Process.flag(:trap_exit, true)

    :ok
  end

  test "will start all streams in store" do
    allow(Broadcast.Stream.Supervisor.start_child(any()), return: {:ok, :pid})

    loads = [
      Load.new!(
        id: "load1",
        dataset_id: "ds1",
        subset_id: "one",
        source: Source.Fake.new!(),
        destination: Channel.Topic.new!(name: "d1")
      ),
      Load.new!(
        id: "load2",
        dataset_id: "ds2",
        subset_id: "two",
        source: Source.Fake.new!(),
        destination: Channel.Topic.new!(name: "d2")
      )
    ]

    Brook.Test.with_event(@instance, fn ->
      Enum.each(loads, &Broadcast.Stream.Store.persist/1)
    end)

    start_supervised(Broadcast.Init)

    assert_async do
      assert_called(Broadcast.Stream.Supervisor.start_child(Enum.at(loads, 0)))
      assert_called(Broadcast.Stream.Supervisor.start_child(Enum.at(loads, 1)))
    end
  end
end

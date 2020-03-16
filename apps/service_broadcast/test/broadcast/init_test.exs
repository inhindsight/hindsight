defmodule Broadcast.InitTest do
  use ExUnit.Case
  require Temp.Env

  @instance Broadcast.Application.instance()

  Temp.Env.modify([
    %{
      app: :service_broadcast,
      key: Broadcast.Stream.Broadway,
      set: [
        configuration: BroadwayConfigurator.Dummy
      ]
    }
  ])

  setup do
    Process.flag(:trap_exit, true)

    :ok
  end

  test "will start all streams in store" do
    loads = [
      Load.Broadcast.new!(
        id: "load1",
        dataset_id: "ds1",
        subset_id: "one",
        source: "s1",
        destination: "d1"
      ),
      Load.Broadcast.new!(
        id: "load2",
        dataset_id: "ds2",
        subset_id: "two",
        source: "s2",
        destination: "d2"
      )
    ]

    Brook.Test.with_event(@instance, fn ->
      Enum.each(loads, &Broadcast.Stream.Store.persist/1)
    end)

    start_supervised(Broadcast.Init)
    Broadcast.Stream.Supervisor.kill_all_children()
  end
end

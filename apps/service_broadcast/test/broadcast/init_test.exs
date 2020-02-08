defmodule Broadcast.InitTest do
  use ExUnit.Case

  @instance Broadcast.Application.instance()

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

    {:ok, pid} = Broadcast.Init.start_link([])

    assert_down(pid)
  end

  defp assert_down(pid) do
    ref = Process.monitor(pid)
    Process.exit(pid, :kill)
    assert_receive {:DOWN, ^ref, _, _, _}
  end
end

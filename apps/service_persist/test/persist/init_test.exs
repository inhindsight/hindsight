defmodule Persist.InitTest do
  use ExUnit.Case
  use Placebo

  @instance Persist.Application.instance()

  setup do
    Brook.Test.clear_view_state(@instance, "loads")

    load =
      Load.Persist.new!(
        id: "persist-1",
        dataset_id: "ds1",
        subset_id: "sb1",
        source: "topic-a",
        destination: "table_a"
      )

    [load: load]
  end

  test "starts Persist.Loader for in process loads", %{load: load} do
    allow Persist.Load.Supervisor.start_child(any()), return: {:ok, :pid}

    Brook.Test.with_event(@instance, fn ->
      Persist.Load.Store.persist(load)
    end)

    assert {:ok, :state} = Persist.Init.on_start(:state)

    assert_called Persist.Load.Supervisor.start_child(load)
  end

  test "start Persist.Compaction for any loads marked for compaction", %{load: load} do
    allow Persist.Compact.Supervisor.start_child(any()), return: {:ok, :pid}

    Brook.Test.with_event(@instance, fn ->
      Persist.Load.Store.persist(load)
      Persist.Load.Store.mark_for_compaction(load)
    end)

    assert {:ok, :state} = Persist.Init.on_start(:state)

    assert_called Persist.Compact.Supervisor.start_child(load)
  end
end

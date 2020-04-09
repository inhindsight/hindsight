defmodule Persist.InitTest do
  use ExUnit.Case
  use Placebo
<<<<<<< HEAD
  import Definition, only: [identifier: 1]
  alias Persist.ViewState
=======
  import AssertAsync
>>>>>>> Helm tweaks for using Postgres view state backend

  @instance Persist.Application.instance()

  setup do
    on_exit(fn ->
      Brook.Test.clear_view_state(@instance, ViewState.Loads.collection())
      Brook.Test.clear_view_state(@instance, ViewState.Compactions.collection())
    end)

    load1 =
      Load.new!(
        id: "persist-1",
        dataset_id: "ds1",
        subset_id: "sb1",
        source: Source.Fake.new!(),
        destination: Destination.Fake.new!()
      )

    load2 =
      Load.new!(
        id: "persist-2",
        dataset_id: "ds2",
        subset_id: "sb2",
        source: Source.Fake.new!(),
        destination: Destination.Fake.new!()
      )

    Brook.Test.with_event(@instance, fn ->
      Enum.each([load1, load2], &ViewState.Loads.persist(identifier(&1), &1))
      ViewState.Compactions.persist(identifier(load1), load1)
    end)

    [load1: load1, load2: load2]
  end

  test "starts loader or compactor processes based on compaction state", %{
    load1: load1,
    load2: load2
  } do
    allow Persist.Load.Supervisor.start_child(any()), return: {:ok, :pid}
    allow Persist.Compact.Supervisor.start_child(any()), return: {:ok, :pid}

<<<<<<< HEAD
    assert {:ok, :state} = Persist.Init.on_start(:state)

    assert_called Persist.Load.Supervisor.start_child(load2)
    assert_called Persist.Compact.Supervisor.start_child(load1)
=======
    Brook.Test.with_event(@instance, fn ->
      Persist.Load.Store.mark_done(load)
    end)

    assert_async do
      assert {:ok, :state} = Persist.Init.on_start(:state)
      refute_called Persist.Compact.Supervisor.start_child(load)
    end
>>>>>>> Helm tweaks for using Postgres view state backend
  end
end

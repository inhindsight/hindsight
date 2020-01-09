defmodule Gather.Case do
  use ExUnit.CaseTemplate

  setup do
    instance = Gather.Application.instance()
    collection = Gather.Extraction.Store.collection()
    Brook.Test.clear_view_state(instance, collection)

    on_exit(fn ->
      child_pids =
        DynamicSupervisor.which_children(Gather.Extraction.Supervisor)
        |> Enum.map(fn {_, pid, _, _} -> pid end)

      refs = Enum.map(child_pids, &Process.monitor/1)

      Enum.each(child_pids, &Process.exit(&1, :kill))

      Enum.each(refs, fn ref ->
        assert_receive {:DOWN, ^ref, _, _, _}, 1_000
      end)
    end)

    :ok
  end
end

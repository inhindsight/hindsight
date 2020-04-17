defmodule Persist.Init do
  @moduledoc """
  Implementation of `Initializer` behaviour to reconnect to
  pre-existing event state.
  """
  use Initializer,
    name: __MODULE__,
    supervisor: Persist.Load.Supervisor

  def on_start(state) do
    with {:ok, compactions} <- Persist.ViewState.Compactions.get_all(),
         {:ok, loads} <- Persist.ViewState.Loads.get_all() do
      Enum.split_with(loads, fn load -> load in compactions end)
      |> start_load_or_compaction()

      Ok.ok(state)
    end
  end

  defp start_load_or_compaction({compacting, compacted}) do
    Enum.each(compacting, &Persist.Compact.Supervisor.start_child/1)
    Enum.each(compacted, &Persist.Load.Supervisor.start_child/1)
  end
end

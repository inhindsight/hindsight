defmodule Gather.Init do
  @moduledoc """
  Implementation of `Initializer` behaviour to reconnect to
  pre-existing event state.
  """
  use Initializer,
    name: __MODULE__,
    supervisor: Gather.Extraction.Supervisor

  alias Gather.Extraction

  def on_start(state) do
    with {:ok, view_state} <- Gather.ViewState.Extractions.get_all() do
      Enum.each(view_state, &Extraction.Supervisor.start_child/1)

      Ok.ok(state)
    end
  end

  defp restore_state_from_store(store) do
    store
    |> Enum.reject(&is_nil/1)
    |> Enum.reject(&Extraction.Store.done?(&1))
    |> Enum.each(&Extraction.Supervisor.start_child/1)
  end
end

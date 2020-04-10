defmodule Gather.Init do
  use Initializer,
    name: __MODULE__,
    supervisor: Gather.Extraction.Supervisor

  alias Gather.Extraction

  def on_start(state) do
    case Extraction.Store.get_all() do
      {:ok, store} ->
        restore_state_from_store(store)
        {:ok, state}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp restore_state_from_store(store) do
    store
    |> Enum.reject(&is_nil/1)
    |> Enum.reject(&Extraction.Store.done?(&1))
    |> Enum.each(&Extraction.Supervisor.start_child/1)
  end
end

defmodule Persist.Init do
  @moduledoc """
  Implementation of `Initializer` behaviour to reconnect to
  pre-existing event state.
  """
  use Initializer,
    name: __MODULE__,
    supervisor: Persist.Load.Supervisor

  def on_start(state) do
    case Persist.Load.Store.get_all() do
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
    |> Enum.reject(&Persist.Load.Store.done?/1)
    |> Enum.map(fn load -> {load, Persist.Load.Store.is_being_compacted?(load)} end)
    |> Enum.each(&start/1)
  end

  defp start({load, false = _compacted?}) do
    Persist.Load.Supervisor.start_child(load)
  end

  defp start({load, true = _compacted?}) do
    Persist.Compact.Supervisor.start_child(load)
  end
end

defmodule Persist.Init do
  use Retry
  use Initializer,
    name: __MODULE__,
    supervisor: Persist.Load.Supervisor

  def on_start(state) do
    retry with: constant_backoff(100) do
      Persist.Load.Store.get_all!()
      |> Enum.reject(&is_nil/1)
      |> Enum.reject(&Persist.Load.Store.done?/1)
      |> Enum.map(fn load -> {load, Persist.Load.Store.is_being_compacted?(load)} end)
      |> Enum.each(&start/1)
    after
      _ ->
        {:ok, state}
    else
      _ -> {:stop, "Could not read state from store", state}
    end
  end

  defp start({load, false = _compacted?}) do
    Persist.Load.Supervisor.start_child(load)
  end

  defp start({load, true = _compacted?}) do
    Persist.Compact.Supervisor.start_child(load)
  end
end

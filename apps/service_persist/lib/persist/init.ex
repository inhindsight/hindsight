defmodule Persist.Init do
  use Initializer,
    name: __MODULE__,
    supervisor: Persist.Load.Supervisor

  def on_start(state) do
    Persist.Load.Store.get_all!()
    |> Enum.reject(&is_nil/1)
    |> Enum.reject(&Persist.Load.Store.done?/1)
    |> Enum.map(fn load -> {load, Persist.Load.Store.is_being_compacted?(load)} end)
    |> Enum.each(&start/1)

    {:ok, state}
  end

  defp start({load, false = _compacted?}) do
    Persist.Load.Supervisor.start_child(load)
  end

  defp start({load, true = _compacted?}) do
    Persist.Compact.Supervisor.start_child(load)
  end
end

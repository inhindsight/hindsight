defmodule Persist.Init do
  use Initializer,
    name: __MODULE__,
    supervisor: Persist.Load.Supervisor

  def on_start(state) do
    Persist.Load.Store.get_all!()
    |> Enum.each(fn load ->
      Persist.Load.Supervisor.start_child({Persist.Load.Broadway, load: load})
    end)

    {:ok, state}
  end
end

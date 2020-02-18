defmodule Persist.Load.Supervisor do
  use Management.Supervisor, name: __MODULE__

  @impl Management.Supervisor
  def say_my_name(%Load.Persist{} = load) do
    Persist.Load.Registry.via(:"#{load.source}")
  end

  @impl Management.Supervisor
  def on_start_child(%Load.Persist{} = load, name) do
    {Persist.Loader, load: load, name: name}
  end
end

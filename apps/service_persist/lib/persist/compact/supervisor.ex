defmodule Persist.Compact.Supervisor do
  use Management.Supervisor,
    name: __MODULE__

  import Definition, only: [identifier: 1]

  @impl Management.Supervisor
  def say_my_name(%Load.Persist{} = load) do
    identifier(load)
    |> Persist.Compact.Registry.via()
  end

  @impl Management.Supervisor
  def on_start_child(%Load.Persist{} = load, name) do
    {Persist.Compaction, load: load, name: name}
  end
end

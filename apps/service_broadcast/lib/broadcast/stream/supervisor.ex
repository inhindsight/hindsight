defmodule Broadcast.Stream.Supervisor do
  use Management.Supervisor, name: __MODULE__

  import Definition, only: [identifier: 1]

  @impl true
  def say_my_name(%Load.Broadcast{} = load) do
    identifier(load)
    |> Broadcast.Stream.Registry.via()
  end

  @impl true
  def on_start_child(%Load.Broadcast{} = load, name) do
    {Broadcast.Stream, load: load, name: name}
  end
end

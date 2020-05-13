defmodule Broadcast.Stream.Supervisor do
  @moduledoc """
  `DynamicSupervisor` implementation. See
  [Management.Supervisor](../../../../management/lib/management/supervisor.ex)
  for more details.
  """
  use Management.Supervisor, name: __MODULE__

  import Definition, only: [identifier: 1]

  @impl true
  def say_my_name(%Load{} = load) do
    identifier(load)
    |> Broadcast.Stream.Registry.via()
  end

  @impl true
  def on_start_child(%Load{} = load, name) do
    {Broadcast.Stream, load: load, name: name}
  end
end

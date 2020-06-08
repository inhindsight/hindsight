defmodule Aggregate.Feed.Supervisor do
  @moduledoc """
  `DynamicSupervisor` implementation. See
  [Management.Supervisor](../../../../management/lib/management/supervisor.ex)
  for more details.
  """
  use Management.Supervisor, name: __MODULE__

  import Definition, only: [identifier: 1]

  @impl Management.Supervisor
  def say_my_name(%Extract{} = extract) do
    identifier(extract)
    |> Aggregate.Feed.Registry.via()
  end

  @impl Management.Supervisor
  def on_start_child(%Extract{} = extract, name) do
    {Aggregate.Feed, extract: extract, name: name}
  end
end

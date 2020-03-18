defmodule Profile.Feed.Supervisor do
  use Management.Supervisor, name: __MODULE__

  import Definition, only: [identifier: 1]

  @impl Management.Supervisor
  def say_my_name(%Extract{} = extract) do
    identifier(extract)
    |> Profile.Feed.Registry.via()
  end

  @impl Management.Supervisor
  def on_start_child(%Extract{} = extract, name) do
    {Profile.Feed, extract: extract, name: name}
  end
end

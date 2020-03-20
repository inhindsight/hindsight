defmodule Profile.Init do
  use Initializer,
    name: __MODULE__,
    supervisor: Profile.Feed.Supervisor

  def on_start(state) do
    Profile.Feed.Store.get_all_extracts!()
    |> Enum.each(&Profile.Feed.Supervisor.start_child/1)

    {:ok, state}
  end
end

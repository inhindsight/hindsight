defmodule Profile.Init do
  use Retry
  use Initializer,
    name: __MODULE__,
    supervisor: Profile.Feed.Supervisor

  def on_start(state) do
    retry with: constant_backoff(100) do
      Profile.Feed.Store.get_all_extracts!()
      |> Enum.each(&Profile.Feed.Supervisor.start_child/1)
    after
      _ ->
        {:ok, state}
    else
      _ -> {:stop, "Could not read state from store", state}
    end
  end
end

defmodule Profile.Init do
  @moduledoc """
  Implementation of `Initializer` behaviour to reconnect to
  pre-existing event state.
  """
  use Initializer,
    name: __MODULE__,
    supervisor: Profile.Feed.Supervisor

  def on_start(state) do
    Profile.Feed.Store.get_all_extracts!()
    |> Enum.each(&Profile.Feed.Supervisor.start_child/1)

    {:ok, state}
  end
end

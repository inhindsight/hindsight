defmodule Profile.Init do
  @moduledoc """
  Implementation of `Initializer` behaviour to reconnect to
  pre-existing event state.
  """
  use Initializer,
    name: __MODULE__,
    supervisor: Profile.Feed.Supervisor

  def on_start(state) do
    with {:ok, view_state} <- Profile.ViewState.Extractions.get_all() do
      Enum.each(view_state, &Profile.Feed.Supervisor.start_child/1)
    end

    Ok.ok(state)
  end
end

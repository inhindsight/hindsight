defmodule Aggregate.Init do
  @moduledoc """
  Implementation of `Initializer` behaviour to reconnect to
  pre-existing event state.
  """
  use Initializer,
    name: __MODULE__,
    supervisor: Aggregate.Feed.Supervisor

  def on_start(state) do
    with {:ok, view_state} <- Aggregate.ViewState.Extractions.get_all() do
      Enum.each(view_state, &Aggregate.Feed.Supervisor.start_child/1)
    end

    Ok.ok(state)
  end
end

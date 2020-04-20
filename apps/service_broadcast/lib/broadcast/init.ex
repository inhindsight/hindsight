defmodule Broadcast.Init do
  @moduledoc """
  Implementation of `Initializer` behaviour to reconnect to
  pre-existing event state.
  """
  use Initializer,
    name: __MODULE__,
    supervisor: Broadcast.Stream.Supervisor

  def on_start(state) do
    with {:ok, view_state} <- Broadcast.ViewState.Streams.get_all() do
      Enum.each(view_state, &Broadcast.Stream.Supervisor.start_child/1)

      Ok.ok(state)
    end
  end
end

defmodule Receive.Init do
  @moduledoc """
  Implementation of `Initializer` behaviour to reconnect to
  pre-existing event state.
  """
  use Initializer,
    name: __MODULE__,
    supervisor: Receive.Accept.Supervisor

  alias Receive.{Accept, SocketManager}

  def on_start(state) do
    with {:ok, view_state} <- Receive.ViewState.Accepts.get_all() do
      Enum.each(view_state, fn accept ->
        Accept.Supervisor.start_child({SocketManager, accept: accept})
      end)

      Ok.ok(state)
    end
  end
end

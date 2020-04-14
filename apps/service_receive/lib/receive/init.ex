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
    Accept.Store.get_all!()
    |> Enum.reject(&is_nil/1)
    |> Enum.reject(&Accept.Store.done?(&1))
    |> Enum.each(fn accept ->
      Accept.Supervisor.start_child({SocketManager, accept: accept})
    end)

    {:ok, state}
  end
end

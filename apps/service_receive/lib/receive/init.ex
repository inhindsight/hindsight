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
    case Accept.Store.get_all() do
      {:ok, store} ->
        restore_state_from_store(store)
        {:ok, state}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp restore_state_from_store(store) do
    store
    |> Enum.reject(&is_nil/1)
    |> Enum.reject(&Accept.Store.done?(&1))
    |> Enum.each(fn accept ->
      Accept.Supervisor.start_child({SocketManager, accept: accept})
    end)
  end
end

defmodule Receive.Init do
  use Retry
  use Initializer,
    name: __MODULE__,
    supervisor: Receive.Accept.Supervisor

  alias Receive.{Accept, SocketManager}

  def on_start(state) do
    retry with: constant_backoff(100) do
      Accept.Store.get_all!()
      |> Enum.reject(&is_nil/1)
      |> Enum.reject(&Accept.Store.done?(&1))
      |> Enum.each(fn accept ->
        Accept.Supervisor.start_child({SocketManager, accept: accept})
      end)
    after
      _ ->
        {:ok, state}
    else
      _ -> {:stop, "Could not read state from store", state}
    end
  end
end

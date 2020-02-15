defmodule Receive.Init do
  use Initializer,
    name: __MODULE__,
    supervisor: Receive.Accept.Supervisor

  alias Receive.{Accept, SocketManager}

  def on_start(state) do
    Accept.Store.get_all!()
    |> Enum.each(fn accept ->
      Accept.Supervisor.start_child({SocketManager, accept: accept})
    end)

    {:ok, state}
  end
end

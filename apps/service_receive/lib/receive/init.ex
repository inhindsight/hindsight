defmodule Receive.Init do
  use Initializer,
    name: __MODULE__,
    supervisor: Receive.Acception.Supervisor

  alias Receive.{Acception, SocketManager}

  def on_start(state) do
    Acception.Store.get_all!()
    |> Enum.each(fn accept ->
      Acception.Supervisor.start_child({SocketManager, accept: accept})
    end)

    {:ok, state}
  end
end

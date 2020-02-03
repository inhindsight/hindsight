defmodule Receive.Init do
  use Initializer,
    name: __MODULE__,
    supervisor: Receive.Socket.Supervisor

  alias Receive.Socket

  def on_start(state) do
    Socket.Store.get_all!()
    |> Enum.each(fn accept ->
      Socket.Supervisor.start_child({Socket, accept: accept})
    end)

    {:ok, state}
  end
end

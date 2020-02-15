defmodule Receive.Event.Handler do
  use Brook.Event.Handler
  require Logger

  alias Receive.SocketManager
  import Events, only: [accept_start: 0, accept_end: 0]

  def handle_event(%Brook.Event{type: accept_start(), data: %Accept{} = accept}) do
    Logger.debug(fn -> "#{__MODULE__}: Received event #{accept_start()}: #{inspect(accept)}" end)

    Receive.Accept.Supervisor.start_child({SocketManager, accept: accept})
    Receive.Accept.Store.persist(accept)
  end

  def handle_event(%Brook.Event{
        type: accept_end(),
        data: %Accept{dataset_id: id, subset_id: sid} = accept
      }) do
    Logger.debug(fn -> "#{__MODULE__}: Received event #{accept_end()}: #{inspect(accept)}" end)
    Receive.Accept.Store.delete(id, sid)

    Process.whereis(:"#{id}_#{sid}_manager")
    |> Receive.Accept.Supervisor.terminate_child()
  end
end

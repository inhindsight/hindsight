defmodule Receive.Event.Handler do
  use Brook.Event.Handler
  require Logger

  alias Receive.Receipt.Store
  import Events, only: [accept_start: 0, accept_end: 0]

  def handle_event(%Brook.Event{type: accept_start(), data: %Accept{} = accept}) do
    Logger.debug(fn -> "#{__MODULE__}: Received event #{accept_start()}: #{inspect(accept)}" end)

    Store.persist(accept)
  end

  def handle_event(%Brook.Event{type: accept_end(), data: %Accept{} = accept}) do
    Store.delete(accept.id)
  end
end

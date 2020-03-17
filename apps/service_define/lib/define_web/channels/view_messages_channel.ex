defmodule Define.ViewMessages.Channel do
  use DefineWeb, :channel
  require Logger
  alias Define.ViewState

  def join("view_messages", _payload, socket) do
    send(self(), :after_join)
    {:ok, socket}
  end

  def handle_info(:after_join, socket) do
    push(socket, "view_state_update", ViewState.state(socket.assigns.view_state_server))
    {:noreply, socket}
  end

  def handle_in("ui_event", message, socket) do
    type = Map.get(message, "type")
    payload = Map.delete(message, "type")
    new_state = ViewState.event(socket.assigns.view_state_server, type, payload)
    push(socket, "view_state_update", new_state)
    {:noreply, socket}
  end


  def handle_in(_type, _message, socket) do
    {:noreply, socket}
  end

end

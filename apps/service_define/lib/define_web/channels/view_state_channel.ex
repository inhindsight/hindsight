defmodule ViewState.Channel do
  use DefineWeb, :channel
  require Logger

  def join("view_state", _payload, socket) do
    send(self(), :after_join)
    {:ok, socket}
  end


  def handle_info(:after_join, socket) do
    push(socket, "update", ViewState.Client.state(socket.assigns.view_state_server))
    {:noreply, socket}
  end

  def handle_in("ui_event", message, socket) do
    new_state = ViewState.Client.event(socket.assigns.view_state_server, message)
    push(socket, "update", new_state)
    {:noreply, socket}
  end


  def handle_in(_type, _message, socket) do
    {:noreply, socket}
  end

end

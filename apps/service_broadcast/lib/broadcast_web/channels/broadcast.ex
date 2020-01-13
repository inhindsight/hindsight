defmodule BroadcastWeb.Channel do
  use Phoenix.Channel

  def join("broadcast:" <> _topic, _message, socket) do
    {:ok, socket}
  end

  def handle_in(_type, _message, socket) do
    {:noreply, socket}
  end
end

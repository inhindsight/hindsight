defmodule BroadcastWeb.Channel do
  use Phoenix.Channel

  def join("broadcast:" <> _topic, _message, socket) do
    {:ok, socket}
  end
end

defmodule DefineWeb.UserSocket do
  use Phoenix.Socket
  alias Define.{ViewState, ViewMessages}

  channel "view_messages", ViewMessages.Channel

  def connect(_params, socket, _connect_info) do
    {:ok, view_state_server} = ViewState.start_link([])
    {:ok, assign(socket, view_state_server: view_state_server)}
  end

  def id(_socket), do: nil
end

defmodule Accept.Websocket.Router do
  @moduledoc false
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  match _ do
    send_resp(conn, 404, "Socket not found")
  end
end

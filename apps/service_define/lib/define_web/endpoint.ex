defmodule DefineWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :service_define

  @session_options [
    store: :cookie,
    key: "_define_key",
    signing_salt: "+YSBmf7s"
  ]

  socket "/define-socket", DefineWeb.UserSocket,
    websocket: true,
    longpoll: false

  plug Plug.Static,
    at: "/",
    from: :service_define,
    gzip: true

  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug DefineWeb.Router
end

import Config

config :service_broadcast, DefineWeb.Endpoint,
  http: [port: 4005],
  server: true,
  check_origin: false

use Mix.Config

config :service_define, DefineWeb.Endpoint,
  http: [port: 4002],
  server: false

config :logger, level: :warn

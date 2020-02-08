import Config

config :service_acquire, AcquireWeb.Endpoint,
  http: [port: 4002],
  server: false

config :logger, level: :warn

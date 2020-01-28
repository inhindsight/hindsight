use Mix.Config

config :service_acquire, AcquireWeb.Endpoint,
  http: [port: 4001],
  server: true,
  check_origin: false

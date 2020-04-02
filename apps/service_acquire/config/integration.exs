import Config

config :service_acquire, AcquireWeb.Endpoint,
  http: [port: 4001],
  server: true,
  check_origin: false

config :service_acquire, Acquire.MetricsReporter, port: 9569

import Config

config :service_broadcast, BroadcastWeb.Endpoint,
  http: [port: 4000],
  server: true,
  check_origin: false

config :service_broadcast, Broadcast.MetricsReporter,
  port: 9570

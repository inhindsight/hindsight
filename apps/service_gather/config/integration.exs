import Config

config :service_gather, Gather.MetricsReporter, port: 9572

config :service_gather,
  divo: "docker-compose.yml",
  divo_wait: [dwell: 1_000, max_tries: 120]

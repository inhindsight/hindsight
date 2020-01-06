use Mix.Config

config :writer_presto,
  divo: "docker-compose.yml",
  divo_wait: [dwell: 1000, max_tries: 120]

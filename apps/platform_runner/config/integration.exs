import Config

config :platform_runner,
  divo: "docker-compose.yml",
  divo_wait: [dwell: 1_000, max_tries: 120]

use Mix.Config

config :ex_aws,
  debug_requests: true,
  access_key_id: "testing_access_key",
  secret_access_key: "testing_secret_key",
  region: "local"

config :ex_aws, :s3,
  scheme: "http://",
  host: %{
    "local" => "localhost"
  },
  port: 9000

config :definition_presto,
  divo: "docker-compose.yml",
  divo_wait: [dwell: 1000, max_tries: 120]

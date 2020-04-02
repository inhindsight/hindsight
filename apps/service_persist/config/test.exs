use Mix.Config

config :logger, level: :debug

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

config :dlq, Dlq.Application, init?: false

config :service_persist,
  divo: "docker-compose.yml",
  divo_wait: [dwell: 1000, max_tries: 120]

config :service_persist, Persist.Application,
  init?: false,
  kafka_endpoints: nil,
  brook: [
    driver: [
      module: Brook.Driver.Test,
      init_arg: []
    ],
    handlers: [Persist.Event.Handler],
    storage: [
      module: Brook.Storage.Ets,
      init_arg: []
    ],
    dispatcher: Brook.Dispatcher.Noop
  ]

config :service_persist, Persist.Loader, max_retries: 3

config :service_persist, Persist.MetricsReporter, port: 9574

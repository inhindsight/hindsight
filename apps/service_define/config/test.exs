use Mix.Config

config :service_define, DefineWeb.Endpoint,
  http: [port: 4002],
  server: false

config :service_define, Define.Application,
  kafka_endpoints: nil,
  brook: [
    driver: [
      module: Brook.Driver.Test,
      init_arg: []
    ],
    handlers: [Define.Event.Handler],
    storage: [
      module: Brook.Storage.Ets,
      init_arg: []
    ],
    dispatcher: Brook.Dispatcher.Noop
  ]

# Print only warnings and errors during test
config :logger, level: :warn

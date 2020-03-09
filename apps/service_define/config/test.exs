use Mix.Config

config :service_define, DefineWeb.Endpoint,
  http: [port: 4005],
  server: false

config :logger, level: :warn

config :service_broadcast, Define.Application,
  init?: false,
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

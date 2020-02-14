import Config

config :service_acquire, AcquireWeb.Endpoint,
  http: [port: 4002],
  server: false

config :logger, level: :debug

config :service_acquire, Acquire.Application,
  brook: [
    driver: [
      module: Brook.Driver.Test,
      init_arg: []
    ],
    handlers: [Acquire.Event.Handler],
    storage: [
      module: Brook.Storage.Ets,
      init_arg: [],
    ],
    dispatcher: Brook.Dispatcher.Noop
  ]

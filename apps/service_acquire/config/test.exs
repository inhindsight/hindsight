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
      module: Brook.Storage.Redis,
      init_arg: [redix_args: [host: "localhost"], namespace: "hindsight"]
    ],
    dispatcher: Brook.Dispatcher.Noop
  ]

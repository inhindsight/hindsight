use Mix.Config

config :service_orchestrate, Orchestrate.Application,
  brook: [
    driver: [
      module: Brook.Driver.Test,
      init_arg: []
    ],
    handlers: [Orchestrate.Event.Handler],
    storage: [
      module: Brook.Storage.Redis,
      init_arg: [redix_args: [host: "localhost"], namespace: "hindsight"]
    ],
    dispatcher: Brook.Dispatcher.Noop
  ]

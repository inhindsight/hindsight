use Mix.Config

config :service_gather, Gather.Application,
  kafka_endpoints: nil,
  brook: [
    driver: [
      module: Brook.Driver.Test,
      init_arg: []
    ],
    handlers: [Gather.Event.Handler],
    storage: [
      module: Brook.Storage.Redis,
      init_arg: [redix_args: [host: "localhost"], namespace: "hindsight"]
    ],
    dispatcher: Brook.Dispatcher.Noop
  ]

config :service_gather, Gather.Application, init?: false

config :service_gather, Gather.Extraction, max_tries: 3

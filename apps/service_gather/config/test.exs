use Mix.Config

config :dlq, Dlq.Application,
  init?: false

config :service_gather, Gather.Application,
  kafka_endpoints: nil,
  brook: [
    driver: [
      module: Brook.Driver.Test,
      init_arg: []
    ],
    handlers: [Gather.Event.Handler],
    storage: [
      module: Brook.Storage.Ets,
      init_arg: []
    ],
    dispatcher: Brook.Dispatcher.Noop
  ]

config :service_gather, Gather.Application, init?: false

config :service_gather, Gather.Extraction, max_tries: 3

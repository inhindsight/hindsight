use Mix.Config

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

config :service_persist, Persist.Load.Broadway,
  broadway_config: [
    producer: [
      module: {Broadway.DummyProducer, []},
      stages: 1
    ],
    processors: [
      default: [
        stages: 1
      ]
    ],
    batchers: [
      default: [
        stages: 1,
        batch_size: 100
      ]
    ]
  ]

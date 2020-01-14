use Mix.Config

config :service_persist,
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

config :service_persist, Persist.Application, init?: false

config :service_persist, Persist.Writer,
  writer: Writer.PrestoMock,
  url: "http://localhost:8080",
  user: "test_user",
  catalog: "test_catalog",
  schema: "test_schema"

config :service_persist, Persist.Load.Broadway,
  writer: Persist.WriterMock,
  dlq: Persist.DLQMock,
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

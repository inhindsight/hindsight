import Config

config :service_broadcast, BroadcastWeb.Endpoint,
  http: [port: 4002],
  server: false

config :logger, level: :warn

config :service_broadcast, Broadcast.Application,
  init?: false,
  kafka_endpoints: nil,
  brook: [
    driver: [
      module: Brook.Driver.Test,
      init_arg: []
    ],
    handlers: [Broadcast.Event.Handler],
    storage: [
      module: Brook.Storage.Redis,
      init_arg: [redix_args: [host: "localhost"], namespace: "hindsight"]
    ],
    dispatcher: Brook.Dispatcher.Noop
  ]

config :service_broadcast, Broadcast.Stream.Broadway,
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
        stages: 1
      ]
    ]
  ]

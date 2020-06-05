use Mix.Config

config :service_aggregate,
  divo: [
    {DivoKafka, [create_topics: "topic1:1:1"]}
  ],
  divo_wait: [dwell: 700, max_tries: 50]

config :service_aggregate, Aggregate.Application,
  init?: false,
  brook: [
    driver: [
      module: Brook.Driver.Test,
      init_arg: []
    ],
    handlers: [Aggregate.Event.Handler],
    storage: [
      module: Brook.Storage.Ets,
      init_arg: []
    ],
    dispatcher: Brook.Dispatcher.Noop
  ]

config :service_aggregate, Aggregate.MetricsReporter, port: 9675

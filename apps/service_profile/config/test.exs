use Mix.Config

config :service_profile,
  divo: [
    {DivoKafka, [create_topics: "topic1:1:1"]}
  ],
  divo_wait: [dwell: 700, max_tries: 50]

config :service_profile, Profile.Application,
  init?: false,
  brook: [
    driver: [
      module: Brook.Driver.Test,
      init_arg: []
    ],
    handlers: [Profile.Event.Handler],
    storage: [
      module: Brook.Storage.Ets,
      init_arg: []
    ],
    dispatcher: Brook.Dispatcher.Noop
  ]

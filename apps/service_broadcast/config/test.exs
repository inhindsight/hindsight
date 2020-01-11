use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :service_broadcast, BroadcastWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

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
    ]
  ]

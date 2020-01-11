import Config
#
# Both compilation and runtime configuration should be set here across all apps.
# Non-prod specific environment configuration should reside in an app's config
# file for that Mix environment. For example: apps/my_app/config/test.exs.
#
# Configuration accessing environment variables should ALWAYS set a default,
# as this configuration will ALWAYS be evaluated.
#
# Example:
#
#     config :my_app, :some_key,
#       abc: 123,
#       foo: System.get_env("FOO", "bar:baz")
#

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# SERVICE_GATHER
kafka_endpoints =
  System.get_env("KAFKA_ENDPOINTS", "localhost:9092")
  |> String.split(",")
  |> Enum.map(&String.trim/1)
  |> Enum.map(fn entry -> String.split(entry, ":") end)
  |> Enum.map(fn [host, port] -> {String.to_atom(host), String.to_integer(port)} end)

config :service_gather,
  app_name: "service_gather",
  topic_prefix: "gather",
  kafka_endpoints: kafka_endpoints,
  brook: [
    driver: [
      module: Brook.Driver.Kafka,
      init_arg: [
        endpoints: kafka_endpoints,
        topic: "event-stream",
        group: "gather-event-stream",
        consumer_config: [
          begin_offset: :earliest,
          offset_reset_policy: :reset_to_earliest
        ]
      ]
    ],
    handlers: [Gather.Event.Handler],
    storage: [
      module: Brook.Storage.Ets,
      init_arg: []
    ],
    dispatcher: Brook.Dispatcher.Noop
  ]

# SERVICE BROADCAST
config :service_broadcast, BroadcastWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "d2cgmPzW+bqVjs99FUeKJ0kOm0w8EZBvLS7UBM8EHi6uBKgW2oBAa9pR2KSu8Z2W",
  render_errors: [view: BroadcastWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: Broadcast.PubSub, adapter: Phoenix.PubSub.PG2]

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

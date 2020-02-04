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

presto_db = [url: "http://localhost:8080", catalog: "hive", schema: "default"]

# SERVICE_GATHER
kafka_endpoints =
  System.get_env("KAFKA_ENDPOINTS", "localhost:9092")
  |> String.split(",")
  |> Enum.map(&String.trim/1)
  |> Enum.map(fn entry -> String.split(entry, ":") end)
  |> Enum.map(fn [host, port] -> {String.to_atom(host), String.to_integer(port)} end)

config :service_gather, Gather.Application,
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

config :service_gather, Gather.Extraction, app_name: "service_gather"

config :service_gather, Gather.Writer,
  app_name: "service_gather",
  kafka_endpoints: kafka_endpoints

# SERVICE BROADCAST
config :service_broadcast, BroadcastWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "d2cgmPzW+bqVjs99FUeKJ0kOm0w8EZBvLS7UBM8EHi6uBKgW2oBAa9pR2KSu8Z2W",
  render_errors: [view: BroadcastWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: Broadcast.PubSub, adapter: Phoenix.PubSub.PG2]

config :service_broadcast, Broadcast.Application,
  kafka_endpoints: kafka_endpoints,
  brook: [
    driver: [
      module: Brook.Driver.Kafka,
      init_arg: [
        endpoints: kafka_endpoints,
        topic: "event-stream",
        group: "broadcast-event-stream",
        consumer_config: [
          begin_offset: :earliest,
          offset_reset_policy: :reset_to_earliest
        ]
      ]
    ],
    handlers: [Broadcast.Event.Handler],
    storage: [
      module: Brook.Storage.Ets,
      init_arg: []
    ],
    dispatcher: Brook.Dispatcher.Noop
  ]

config :service_broadcast, Broadcast.Stream.Broadway,
  app_name: "service_broadcast",
  broadway_config: [
    producer: [
      module:
        {OffBroadway.Kafka.Producer,
         [
           endpoints: kafka_endpoints,
           create_topics: true,
           group_consumer: [
             config: [
               begin_offset: :earliest,
               prefetch_count: 0,
               prefetch_bytes: 2_097_152
             ]
           ]
         ]},
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
        batch_size: 100,
        batch_timeout: 1_000
      ]
    ]
  ]

# SERVICE PERSIST
config :service_persist, Persist.Application,
  kafka_endpoints: kafka_endpoints,
  brook: [
    driver: [
      module: Brook.Driver.Kafka,
      init_arg: [
        endpoints: kafka_endpoints,
        topic: "event-stream",
        group: "persist-event-stream",
        consumer_config: [
          begin_offset: :earliest,
          offset_reset_policy: :reset_to_earliest
        ]
      ]
    ],
    handlers: [Persist.Event.Handler],
    storage: [
      module: Brook.Storage.Ets,
      init_arg: []
    ],
    dispatcher: Brook.Dispatcher.Noop,
    event_processing_timeout: 20_000
  ]

config :service_persist, Persist.TableCreator.Presto,
  url: "http://localhost:8080",
  user: "hindsight",
  catalog: "hive",
  schema: "default"

config :service_persist, Persist.Uploader.S3,
  s3_bucket: "kdp-cloud-storage",
  s3_path: "hive-s3"

config :service_persist, Persist.Load.Broadway,
  app_name: "service_persist",
  broadway_config: [
    producer: [
      module:
        {OffBroadway.Kafka.Producer,
         [
           endpoints: kafka_endpoints,
           create_topics: true,
           group_consumer: [
             config: [
               begin_offset: :earliest,
               prefetch_count: 0,
               prefetch_bytes: 2_097_152
             ]
           ]
         ]},
      stages: 1
    ],
    processors: [
      default: [
        stages: 100
      ]
    ],
    batchers: [
      default: [
        stages: 1,
        batch_size: 1000,
        batch_timeout: 2_000
      ]
    ]
  ]

# SERVICE ORCHESTRATE
config :service_orchestrate, Orchestrate.Application,
  brook: [
    driver: [
      module: Brook.Driver.Kafka,
      init_arg: [
        endpoints: kafka_endpoints,
        topic: "event-stream",
        group: "orchestrate-event-stream",
        consumer_config: [
          begin_offset: :earliest,
          offset_reset_policy: :reset_to_earliest
        ]
      ]
    ],
    handlers: [Orchestrate.Event.Handler],
    storage: [
      module: Brook.Storage.Ets,
      init_arg: []
    ],
    dispatcher: Brook.Dispatcher.Noop
  ]

# SERVICE ACQUIRE
config :service_acquire, Acquire.Db.Presto, presto: Keyword.put(presto_db, :user, "acquire")

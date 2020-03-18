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
config :logger,
  level: :warn,
  console: [
    format: "$time $metadata[$level] $message\n",
    metadata: [:request_id]
  ]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

secret_key_base =
  System.get_env(
    "SECRET_KEY_BASE",
    "d2cgmPzW+bqVjs99FUeKJ0kOm0w8EZBvLS7UBM8EHi6uBKgW2oBAa9pR2KSu8Z2W"
  )

presto_db = [
  url: System.get_env("PRESTO_URL", "http://localhost:8080"),
  catalog: "hive",
  schema: "default"
]

kafka_endpoints =
  System.get_env("KAFKA_ENDPOINTS", "localhost:9092")
  |> String.split(",")
  |> Enum.map(&String.trim/1)
  |> Enum.map(fn entry -> String.split(entry, ":") end)
  |> Enum.map(fn [host, port] -> {String.to_atom(host), String.to_integer(port)} end)

redix_args = [host: System.get_env("REDIS_HOST", "localhost")]
config :redix, :args, redix_args

# SERVICE_RECEIVE
config :service_receive, Receive.Application,
  kafka_endpoints: kafka_endpoints,
  brook: [
    driver: [
      module: Brook.Driver.Kafka,
      init_arg: [
        endpoints: kafka_endpoints,
        topic: "event-stream",
        group: "receive-event-stream",
        consumer_config: [
          begin_offset: :earliest,
          offset_reset_policy: :reset_to_earliest
        ]
      ]
    ],
    handlers: [Receive.Event.Handler],
    storage: [
      module: Brook.Storage.Redis,
      init_arg: [redix_args: redix_args, namespace: "service:receive:view"]
    ],
    dispatcher: Brook.Dispatcher.Noop
  ]

config :service_receive, Receive.Writer,
  app_name: "service_receive",
  kafka_endpoints: kafka_endpoints

# SERVICE_GATHER
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
      module: Brook.Storage.Redis,
      init_arg: [redix_args: redix_args, namespace: "service:gather:view"]
    ],
    dispatcher: Brook.Dispatcher.Noop
  ]

config :service_gather, Gather.Extraction, app_name: "service_gather"

config :service_gather, Gather.Writer,
  app_name: "service_gather",
  kafka_endpoints: kafka_endpoints

# SERVICE BROADCAST
config :service_broadcast, BroadcastWeb.Endpoint,
  http: [:inet6, port: String.to_integer(System.get_env("PORT") || "4000")],
  secret_key_base: secret_key_base,
  render_errors: [view: BroadcastWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: Broadcast.PubSub, adapter: Phoenix.PubSub.PG2],
  server: true,
  check_origin: false

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
      module: Brook.Storage.Redis,
      init_arg: [redix_args: redix_args, namespace: "service:broadcast:view"]
    ],
    dispatcher: Brook.Dispatcher.Noop
  ]

config :service_broadcast, Broadcast.Stream.Broadway.Configuration,
  endpoints: kafka_endpoints,
  broadway_config: [
    producer: [
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
        batch_size: 1_000,
        batch_timeout: 1_000
      ]
    ]
  ]

config :service_broadcast, Broadcast.Stream.Broadway, app_name: "service_broadcast"

# SERVICE PERSIST
bucket_region = [region: System.get_env("BUCKET_REGION", "local")]

object_storage =
  [
    host: System.get_env("BUCKET_HOST"),
    scheme: System.get_env("BUCKET_SCHEME"),
    port: System.get_env("BUCKET_PORT")
  ]
  |> Enum.filter(fn {_, val} -> val end)
  |> Keyword.merge(bucket_region)

config :ex_aws, bucket_region
config :ex_aws, :s3, object_storage

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
      module: Brook.Storage.Redis,
      init_arg: [redix_args: redix_args, namespace: "service:persist:view"]
    ],
    dispatcher: Brook.Dispatcher.Noop,
    event_processing_timeout: 20_000
  ]

config :service_persist, Persist.TableManager.Presto, Keyword.put(presto_db, :user, "hindsight")

config :service_persist, Persist.DataStorage.S3,
  s3_bucket: System.get_env("BUCKET_NAME", "kdp-cloud-storage"),
  s3_path: "hive-s3"

config :service_persist, Persist.Load.Broadway.Configuration,
  endpoints: kafka_endpoints,
  broadway_config: [
    producer: [
      stages: 1
    ],
    processors: [
      default: [
        stages: 100
      ]
    ],
    batchers: [
      default: [
        stages: 2,
        batch_size: 1_000,
        batch_timeout: 2_000
      ]
    ]
  ]

config :service_persist, Persist.Load.Broadway, app_name: "service_persist"

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
      module: Brook.Storage.Redis,
      init_arg: [redix_args: redix_args, namespace: "service:orchestrate:view"]
    ],
    dispatcher: Brook.Dispatcher.Noop
  ]

# SERVICE ACQUIRE
config :service_acquire, AcquireWeb.Endpoint,
  http: [:inet6, port: String.to_integer(System.get_env("PORT") || "4000")],
  secret_key_base: secret_key_base,
  render_errors: [view: AcquireWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: Acquire.PubSub, adapter: Phoenix.PubSub.PG2],
  server: true,
  check_origin: false

config :service_acquire, Acquire.Application,
  brook: [
    driver: [
      module: Brook.Driver.Kafka,
      init_arg: [
        endpoints: kafka_endpoints,
        topic: "event-stream",
        group: "acquire-event-stream",
        consumer_config: [
          begin_offset: :earliest,
          offset_reset_policy: :reset_to_earliest
        ]
      ]
    ],
    handlers: [Acquire.Event.Handler],
    storage: [
      module: Brook.Storage.Redis,
      init_arg: [redix_args: redix_args, namespace: "service:acquire:view"]
    ],
    dispatcher: Brook.Dispatcher.Noop
  ]

config :service_acquire, Acquire.Db.Presto, presto: Keyword.put(presto_db, :user, "acquire")

# SERVICE DEFINE
config :service_define, DefineWeb.Endpoint,
  http: [:inet6, port: String.to_integer(System.get_env("DEFINE_PORT") || "4005")],
  secret_key_base: secret_key_base,
  live_view: [
    signing_salt: secret_key_base
  ],
  render_errors: [view: DefineWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: Define.PubSub, adapter: Phoenix.PubSub.PG2],
  server: true,
  check_origin: false

config :service_define, Define.Application,
  kafka_endpoints: kafka_endpoints,
  brook: [
    driver: [
      module: Brook.Driver.Kafka,
      init_arg: [
        endpoints: kafka_endpoints,
        topic: "event-stream",
        group: "define-event-stream",
        consumer_config: [
          begin_offset: :earliest,
          offset_reset_policy: :reset_to_earliest
        ]
      ]
    ],
    handlers: [Define.Event.Handler],
    storage: [
      module: Brook.Storage.Redis,
      init_arg: [redix_args: redix_args, namespace: "service:define:view"]
    ],
    dispatcher: Brook.Dispatcher.Noop
  ]

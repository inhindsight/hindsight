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

config :dlq, Dlq.Server,
  endpoints: kafka_endpoints,
  topic: "dead-letter-queue"

config :definition_presto, Presto.Table.Destination,
  catalog: "hive",
  user: "hindsight"

config :definition_presto, Presto.Table.DataStorage.S3,
  s3_bucket: System.get_env("BUCKET_NAME", "kdp-cloud-storage"),
  s3_path: "hive-s3"

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
      module: Brook.Storage.Postgres,
      init_arg: [
        table: "receive_state",
        postgrex_args: [
          hostname: System.get_env("RECEIVE_DB_HOST", "localhost"),
          username: System.get_env("RECEIVE_DB_USER", "receive_app_user"),
          password: System.get_env("RECEIVE_DB_PASSWORD", "receive123"),
          database: System.get_env("RECEIVE_DB_NAME", "receive_app_state")
        ]
      ]
    ],
    dispatcher: Brook.Dispatcher.Noop
  ]

config :service_receive, Receive.SocketManager, app_name: "service_receive"

config :service_receive, Receive.Event.Handler, endpoints: kafka_endpoints

# SERVICE_GATHER
config :service_gather, Gather.Application,
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
      module: Brook.Storage.Postgres,
      init_arg: [
        table: "gather_state",
        postgrex_args: [
          hostname: System.get_env("GATHER_DB_HOST", "localhost"),
          username: System.get_env("GATHER_DB_USER", "gather_app_user"),
          password: System.get_env("GATHER_DB_PASSWORD", "gather123"),
          database: System.get_env("GATHER_DB_NAME", "gather_app_state")
        ]
      ]
    ],
    dispatcher: Brook.Dispatcher.Noop
  ]

config :service_gather, Gather.Event.Handler, endpoints: kafka_endpoints
config :service_gather, Gather.Extraction, app_name: "service_gather"
config :service_gather, Gather.Extraction.SourceHandler, app_name: "service_gather"

# SERVICE BROADCAST
config :service_broadcast, BroadcastWeb.Endpoint,
  http: [:inet6, port: String.to_integer(System.get_env("PORT") || "4000")],
  secret_key_base: secret_key_base,
  render_errors: [view: BroadcastWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: Broadcast.PubSub, adapter: Phoenix.PubSub.PG2],
  server: true,
  check_origin: false

config :service_broadcast, Broadcast.Application,
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
      module: Brook.Storage.Postgres,
      init_arg: [
        table: "broadcast_state",
        postgrex_args: [
          hostname: System.get_env("BROADCAST_DB_HOST", "localhost"),
          username: System.get_env("BROADCAST_DB_USER", "broadcast_app_user"),
          password: System.get_env("BROADCAST_DB_PASSWORD", "broadcast123"),
          database: System.get_env("BROADCAST_DB_NAME", "broadcast_app_state")
        ]
      ]
    ],
    dispatcher: Brook.Dispatcher.Noop
  ]

config :service_broadcast, Broadcast.Event.Handler, endpoints: kafka_endpoints

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
      module: Brook.Storage.Postgres,
      init_arg: [
        table: "persist_state",
        postgrex_args: [
          hostname: System.get_env("PERSIST_DB_HOST", "localhost"),
          username: System.get_env("PERSIST_DB_USER", "persist_app_user"),
          password: System.get_env("PERSIST_DB_PASSWORD", "persist123"),
          database: System.get_env("PERSIST_DB_NAME", "persist_app_state")
        ]
      ]
    ],
    dispatcher: Brook.Dispatcher.Noop,
    event_processing_timeout: 20_000
  ]

config :service_persist, Persist.Event.Handler, endpoints: kafka_endpoints

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
      module: Brook.Storage.Postgres,
      init_arg: [
        table: "orchestrate_state",
        postgrex_args: [
          hostname: System.get_env("ORCHESTRATE_DB_HOST", "localhost"),
          username: System.get_env("ORCHESTRATE_DB_USER", "orchestrate_app_user"),
          password: System.get_env("ORCHESTRATE_DB_PASSWORD", "orchestrate123"),
          database: System.get_env("ORCHESTRATE_DB_NAME", "orchestrate_app_state")
        ]
      ]
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
      module: Brook.Storage.Postgres,
      init_arg: [
        table: "acquire_state",
        postgrex_args: [
          hostname: System.get_env("ACQUIRE_DB_HOST", "localhost"),
          username: System.get_env("ACQUIRE_DB_USER", "acquire_app_user"),
          password: System.get_env("ACQUIRE_DB_PASSWORD", "acquire123"),
          database: System.get_env("ACQUIRE_DB_NAME", "acquire_app_state")
        ]
      ]
    ],
    dispatcher: Brook.Dispatcher.Noop
  ]

config :service_acquire, Acquire.Db.Presto, presto: Keyword.put(presto_db, :user, "acquire")

# SERVICE PROFILE
config :service_profile, Profile.Application,
  init?: true,
  brook: [
    driver: [
      module: Brook.Driver.Kafka,
      init_arg: [
        endpoints: kafka_endpoints,
        topic: "event-stream",
        group: "profile-event-stream",
        consumer_config: [
          begin_offset: :earliest,
          offset_reset_policy: :reset_to_earliest
        ]
      ]
    ],
    handlers: [Profile.Event.Handler],
    storage: [
      module: Brook.Storage.Postgres,
      init_arg: [
        table: "profile_state",
        postgrex_args: [
          hostname: System.get_env("PROFILE_DB_HOST", "localhost"),
          username: System.get_env("PROFILE_DB_USER", "profile_app_user"),
          password: System.get_env("PROFILE_DB_PASSWORD", "profile123"),
          database: System.get_env("PROFILE_DB_NAME", "profile_app_state")
        ]
      ]
    ],
    dispatcher: Brook.Dispatcher.Noop
  ]

config :service_profile, Profile.Feed.Producer, endpoints: kafka_endpoints

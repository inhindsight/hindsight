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

config :secret_store, SecretStore, secret_environment: System.get_env("SECRET_ENV", nil)

config :initializer, Initializer.Brook,
  event_topic: System.get_env("EVENT_STREAM", "event-stream"),
  kafka_endpoints: kafka_endpoints,
  secret_store: System.get_env("SECRET_STORE", "environment")

# HOOK_CREATE_DB
config :hook_create_db, CreateDB, secret_store: System.get_env("SECRET_STORE", "environment")

# SERVICE_RECEIVE
config :service_receive, Receive.SocketManager, app_name: "service_receive"
config :service_receive, Receive.Event.Handler, endpoints: kafka_endpoints

# SERVICE_GATHER
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
config :service_persist, Persist.Event.Handler, endpoints: kafka_endpoints

# SERVICE ACQUIRE
config :service_acquire, AcquireWeb.Endpoint,
  http: [:inet6, port: String.to_integer(System.get_env("PORT") || "4000")],
  secret_key_base: secret_key_base,
  render_errors: [view: AcquireWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: Acquire.PubSub, adapter: Phoenix.PubSub.PG2],
  server: true,
  check_origin: false

config :service_acquire, Acquire.Db.Presto, presto: Keyword.put(presto_db, :user, "acquire")

# SERVICE PROFILE
config :service_profile, Profile.Application, init?: true
config :service_profile, Profile.Feed.Producer, endpoints: kafka_endpoints

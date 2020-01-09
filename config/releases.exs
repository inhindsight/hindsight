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

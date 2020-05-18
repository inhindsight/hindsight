defmodule Initializer.Brook do
  @moduledoc """
  Configure event streaming via `Brook` on a per-service basis.
  """
  use Properties, otp_app: :initializer

  getter(:secret_store, required: true)
  getter(:kafka_endpoints, required: true)
  getter(:event_topic, required: true)

  @spec config(atom, String.t(), module) :: keyword
  def config(instance, service_name, event_handler) do
    [
      dispatcher: Brook.Dispatcher.Noop,
      driver: [
        module: Brook.Driver.Kafka,
        init_arg: [
          endpoints: kafka_endpoints(),
          topic: event_topic(),
          group: "#{service_name}-event-stream",
          consumer_config: [
            begin_offset: :earliest,
            offset_reset_policy: :reset_to_earliest
          ]
        ]
      ],
      handlers: [event_handler],
      instance: instance,
      storage: [
        module: Brook.Storage.Postgres,
        init_arg: [
          table: "#{service_name}_state",
          postgrex_args: [
            database: "#{service_name}_view_state",
            hostname: secret().get("hindsight-#{service_name}", "host", "localhost"),
            username: secret().get("hindsight-#{service_name}", "username", "#{service_name}_user"),
            password: secret().get("hindsight-#{service_name}", "password", "#{service_name}123")
          ]
        ]
      ]
    ]
  end

  defp secret do
    storage = secret_store() |> String.capitalize() |> String.to_atom()
    Module.concat([SecretStore, storage])
  end
end

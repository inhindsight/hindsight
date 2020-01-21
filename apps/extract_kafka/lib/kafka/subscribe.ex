defmodule Kafka.Subscribe do
  use Definition, schema: Kafka.Subscribe.V1

  @type t :: %__MODULE__{
          version: integer,
          endpoints: keyword,
          topic: String.t()
        }

  defstruct version: 1, endpoints: nil, topic: nil

  def on_new(data) do
    data
    |> Map.update(:endpoints, [], &transform_endpoints/1)
    |> Ok.ok()
  end

  defp transform_endpoints(list) when is_list(list) do
    Enum.map(list, &transform_endpoint/1)
  end
  defp transform_endpoints(other), do: other

  defp transform_endpoint([host, port]), do: {String.to_atom(host), port}
  defp transform_endpoint(other), do: other

  defimpl Jason.Encoder, for: __MODULE__ do
    def encode(value, opts) do
      Map.from_struct(value)
      |> Map.update!(:endpoints, fn list ->
        Enum.map(list, fn {host, port} -> [host, port] end)
      end)
      |> Jason.Encode.map(opts)
    end
  end

  defimpl Brook.Serializer.Protocol, for: __MODULE__ do
    def serialize(value) do
      Map.from_struct(value)
      |> Map.update!(:endpoints, fn list ->
        Enum.map(list, fn {host, port} -> [host, port] end)
      end)
      |> Ok.ok()
    end
  end

  defimpl Extract.Step, for: __MODULE__ do
    import Extract.Steps.Context
    alias Kafka.Subscribe.Acknowledger

    def execute(%{endpoints: endpoints, topic: topic}, context) do
      ensure_topic(endpoints, topic)
      connection = :"kafka_subscribe_#{topic}"

      {:ok, acknowledger} = Kafka.Subscribe.Acknowledger.start_link(connection: connection)

      source = fn _opts ->
        Stream.resource(
          initialize(endpoints, topic, connection, acknowledger),
          &receive_messages/1,
          &shutdown/1
        )
      end

      context
      |> register_after_function(&acknowledge_values(acknowledger, &1))
      |> set_source(source)
      |> Ok.ok()
    end

    defp acknowledge_values(acknowledger, values) do
      Acknowledger.ack(acknowledger, values)
    end

    defp receive_messages(%{acknowledger: acknowledger} = acc) do
      receive do
        {:kafka_subscribe, messages} ->
          Acknowledger.cache(acknowledger, messages)
          {messages, acc}
      end
    end

    defp ensure_topic(endpoints, topic) do
      unless Elsa.topic?(endpoints, topic) do
        Elsa.create_topic(endpoints, topic)
      end
    end

    defp initialize(endpoints, topic, connection, acknowledger) do
      fn ->
        {:ok, elsa} =
          Elsa.Supervisor.start_link(
            connection: connection,
            endpoints: endpoints,
            group_consumer: [
              group: "kafka_subscribe_#{topic}",
              topics: [topic],
              handler: Kafka.Subscribe.Handler,
              handler_init_args: %{pid: self()},
              config: [
                begin_offset: :earliest,
                offset_reset_policy: :reset_to_earliest,
                prefetch_count: 0,
                prefetch_bytes: 1_000_000
              ]
            ]
          )

        %{elsa_supervisor: elsa, acknowledger: acknowledger}
      end
    end

    defp shutdown(%{elsa_supervisor: elsa, acknowledger: acknowledger} = acc) do
      Process.exit(elsa, :normal)
      Process.exit(acknowledger, :normal)
      acc
    end
  end
end

defmodule Kafka.Subscribe.Handler do
  use Elsa.Consumer.MessageHandler

  def handle_messages(messages, state) do
    send(state.pid, {:kafka_subscribe, messages})
    {:no_ack, state}
  end
end

defmodule Kafka.Subscribe.V1 do
  use Definition.Schema

  def s do
    schema(%Kafka.Subscribe{
      version: version(1),
      endpoints: spec(is_list() and not_nil?()),
      topic: required_string()
    })
  end
end

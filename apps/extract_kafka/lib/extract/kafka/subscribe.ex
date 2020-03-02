defmodule Extract.Kafka.Subscribe do
  use Definition, schema: Extract.Kafka.Subscribe.V1
  require Logger

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

  defimpl Extract.Step, for: __MODULE__ do
    import Extract.Context

    @dialyzer [:no_return, :no_fail_call]

    def execute(%{endpoints: endpoints, topic: topic}, context) do
      ensure_topic(endpoints, topic)
      connection = :"kafka_subscribe_#{topic}"

      source = fn _opts ->
        Stream.resource(
          initialize(endpoints, topic, connection),
          &receive_messages/1,
          &shutdown/1
        )
      end

      context
      |> register_after_function(&acknowledge_messages(connection, &1))
      |> set_source(source)
      |> Ok.ok()
    end

    defp acknowledge_messages(connection, messages) do
      %{
        "topic" => topic,
        "partition" => partition,
        "generation_id" => generation_id,
        "offset" => offset
      } =
        messages
        |> Enum.map(&get_in(&1, [Access.key(:meta), "kafka"]))
        |> Enum.max_by(&Map.get(&1, "offset"))

      :ok = Elsa.Group.Acknowledger.ack(connection, topic, partition, generation_id, offset)
    end

    defp receive_messages(acc) do
      receive do
        {:kafka_subscribe, messages} ->
          Logger.debug(fn -> "#{__MODULE__}: received #{inspect(messages)}" end)

          extract_messages =
            Enum.map(messages, fn %{value: payload} = elsa_message ->
              meta =
                elsa_message
                |> Map.from_struct()
                |> Map.drop([:value, :timestamp, :headers, :key])
                |> Enum.reduce(%{}, fn {k, v}, acc ->
                  Map.put(acc, to_string(k), v)
                end)

              Extract.Message.new(data: payload, meta: %{"kafka" => meta})
            end)

          Logger.debug(fn -> "#{__MODULE__}: adding to source #{inspect(extract_messages)}" end)
          {extract_messages, acc}
      end
    end

    defp ensure_topic(endpoints, topic) do
      unless Elsa.topic?(endpoints, topic) do
        Elsa.create_topic(endpoints, topic)
      end
    end

    defp initialize(endpoints, topic, connection) do
      Logger.debug(fn -> "#{__MODULE__}: Initializing for topic #{topic}" end)

      fn ->
        {:ok, elsa} =
          Elsa.Supervisor.start_link(
            connection: connection,
            endpoints: endpoints,
            group_consumer: [
              group: "kafka_subscribe_#{topic}",
              topics: [topic],
              handler: Extract.Kafka.Subscribe.Handler,
              handler_init_args: %{pid: self()},
              config: [
                begin_offset: :earliest,
                offset_reset_policy: :reset_to_earliest,
                prefetch_count: 0,
                prefetch_bytes: 1_000_000
              ]
            ]
          )

        %{elsa_supervisor: elsa}
      end
    end

    defp shutdown(%{elsa_supervisor: elsa} = acc) do
      Process.exit(elsa, :normal)
      acc
    end
  end
end

defmodule Extract.Kafka.Subscribe.Handler do
  use Elsa.Consumer.MessageHandler
  require Logger

  def handle_messages(messages, state) do
    Logger.debug(fn -> "#{__MODULE__}: received #{inspect(messages)}" end)
    send(state.pid, {:kafka_subscribe, messages})
    {:no_ack, state}
  end
end

defmodule Extract.Kafka.Subscribe.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Extract.Kafka.Subscribe{
      version: version(1),
      endpoints: spec(is_list() and not_nil?()),
      topic: required_string()
    })
  end
end

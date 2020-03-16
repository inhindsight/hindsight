defmodule Writer.Kafka.Topic do
  @behaviour Writer
  use GenServer
  use Retry

  @type init_opts :: [
          name: atom,
          connection: atom,
          endpoints: [{atom, non_neg_integer}],
          topic: String.t(),
          metric_metadata: %{},
          config: %{}
        ]

  defmodule State do
    defstruct [:connection, :endpoints, :topic, :elsa_sup, :metric_metadata, :producer_opts]
  end

  @impl Writer
  def start_link(args) do
    server_opts = [name: Keyword.get(args, :name, nil)]
    GenServer.start_link(__MODULE__, args, server_opts)
  end

  @impl Writer
  def write(server, messages, opts \\ []) do
    GenServer.call(server, {:write, messages, opts})
  end

  @impl GenServer
  def init(opts) do
    topic = Keyword.fetch!(opts, :topic)

    state = %State{
      connection: Keyword.get(opts, :connection, default_connection_name()),
      endpoints: Keyword.fetch!(opts, :endpoints),
      topic: topic,
      metric_metadata: Keyword.get(opts, :metric_metadata, %{}) |> Map.put(:topic, topic),
      producer_opts: determine_producer_opts(opts)
    }

    {:ok, state, {:continue, {:init, opts}}}
  end

  @impl GenServer
  def handle_continue({:init, opts}, state) do
    unless Elsa.topic?(state.endpoints, state.topic) do
      create_topic(state.endpoints, state.topic, opts)
    end

    {:ok, elsa_sup} =
      Elsa.Supervisor.start_link(
        connection: state.connection,
        endpoints: state.endpoints,
        producer: [
          topic: state.topic
        ]
      )

    Elsa.Producer.ready?(state.connection)

    {:noreply, %{state | elsa_sup: elsa_sup}}
  end

  @impl GenServer
  def handle_call({:write, messages, _opts}, _from, state) do
    with :ok <- Elsa.produce(state.connection, state.topic, messages, state.producer_opts) do
      send_metric(state, length(messages))
      {:reply, :ok, state}
    else
      {:error, _reason, failed_messages} = error ->
        count = length(messages) - length(failed_messages)
        send_metric(state, count)
        {:reply, error, state}
    end
  end

  defp create_topic(endpoints, topic, opts) do
    config = Keyword.get(opts, :config, %{})

    create_opts =
      case get_in(config, ["kafka", "partitions"]) do
        nil -> []
        number -> [partitions: number]
      end

    Elsa.create_topic(endpoints, topic, create_opts)

    wait exponential_backoff(100) |> Stream.take(10) do
      Elsa.topic?(endpoints, topic)
    after
      _ -> :ok
    else
      _ -> raise "Timed out waiting for #{topic} to be available"
    end
  end

  defp send_metric(state, count) do
    :telemetry.execute([:writer, :kafka, :produce], %{count: count}, state.metric_metadata)
  end

  defp default_connection_name(), do: :"#{__MODULE__}_#{inspect(self())}"

  defp determine_producer_opts(opts) do
    config = Keyword.get(opts, :config, %{})

    case get_in(config, ["kafka", "partitioner"]) do
      nil -> [partition: 0]
      partitioner -> [partitioner: String.to_atom(partitioner)]
    end
  end
end

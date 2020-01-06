defmodule Writer.Kafka.Topic do
  @behaviour Writer
  use GenServer
  use Retry

  defmodule State do
    defstruct [:connection, :endpoints, :topic, :elsa_sup]
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
    state = %State{
      connection: Keyword.get(opts, :connection, default_connection_name()),
      endpoints: Keyword.fetch!(opts, :endpoints),
      topic: Keyword.fetch!(opts, :topic)
    }

    unless Elsa.topic?(state.endpoints, state.topic) do
      create_topic(state.endpoints, state.topic)
    end

    {:ok, elsa_sup} =
      Elsa.Supervisor.start_link(
        connection: state.connection,
        endpoints: state.endpoints,
        producer: [
          topic: state.topic
        ]
      )

    Ok.ok(%{state | elsa_sup: elsa_sup})
  end

  @impl GenServer
  def handle_call({:write, messages, _opts}, _from, state) do
    Elsa.produce(state.connection, state.topic, messages)
    |> reply(state)
  end

  defp create_topic(endpoints, topic) do
    Elsa.create_topic(endpoints, topic)

    wait exponential_backoff(100) |> Stream.take(10) do
      Elsa.topic?(endpoints, topic)
    after
      _ -> :ok
    else
      _ -> raise "Timed out waiting for #{topic} to be available"
    end
  end

  defp reply(message, state), do: {:reply, message, state}

  defp default_connection_name(), do: :"#{__MODULE__}_#{inspect(self())}"
end

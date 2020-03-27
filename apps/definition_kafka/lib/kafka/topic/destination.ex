defmodule Kafka.Topic.Destination do
  use GenServer, shutdown: 30_000
  use Properties, otp_app: :definition_kafka
  use Annotated.Retry
  require Logger

  getter(:dlq, default: Dlq)

  @spec start_link(Destination.t(), Destination.init_opts()) ::
          {:ok, Destination.t()} | {:error, term}
  def start_link(topic, opts) do
    GenServer.start_link(__MODULE__, {topic, opts})
    |> Ok.map(&%{topic | pid: &1})
  end

  @spec write(Destination.t(), [term]) :: :ok | {:error, term}
  def write(topic, [%{} | _] = messages) do
    encoded =
      Enum.reduce(messages, %{ok: [], error: []}, fn msg, %{ok: ok, error: err} = acc ->
        case Jason.encode(msg) do
          {:ok, json} -> %{acc | ok: [{key(topic, msg), json} | ok]}
          {:error, reason} -> %{acc | error: [{msg, reason} | err]}
        end
      end)

    with :ok <- write(topic, Enum.reverse(encoded.ok)) do
      GenServer.cast(topic.pid, {:dlq, Enum.reverse(encoded.error)})
      :ok
    end
  end

  def write(topic, messages) do
    with {:ok, _} <- do_write(topic, messages) do
      count = Enum.count(messages)
      :telemetry.execute([:destination, :kafka, :write], %{count: count}, topic)
    end
  end

  @spec stop(Destination.t()) :: :ok
  def stop(topic) do
    GenServer.call(topic.pid, :stop)
  end

  @spec delete(Destination.t()) :: :ok | {:error, term}
  def delete(topic) do
    with {:error, reason} <- Elsa.delete_topic(topic.endpoints, topic.name),
         log_reason <- inspect(reason) do
      Logger.warn(fn -> "Topic '#{topic.name}' failed to delete: #{log_reason}" end)
      Ok.error(reason)
    end
  end

  @impl GenServer
  def init({topic, opts}) do
    Process.flag(:trap_exit, true)
    state = Map.new(opts) |> Map.put(:connection, connection_name())
    {:ok, state, {:continue, {:init, topic}}}
  end

  @impl GenServer
  def handle_continue({:init, topic}, state) do
    with opts <- Map.from_struct(topic) |> Enum.into([]),
         :ok <- Elsa.create_topic(topic.endpoints, topic.name, opts),
         {:ok, pid} <- start_producer(topic, state.connection) do
      store_connection(topic, state.connection)
      {:noreply, Map.put(state, :elsa_pid, pid)}
    end
  end

  @impl GenServer
  def handle_call(:stop, _from, state) do
    Logger.info(fn -> "#{__MODULE__}: Terminating by request" end)
    {:stop, :normal, :ok, state}
  end

  @impl GenServer
  def handle_cast({:dlq, []}, state) do
    {:noreply, state}
  end

  def handle_cast({:dlq, messages}, state) do
    Logger.debug(fn -> "#{__MODULE__}: Writing #{Enum.count(messages)} messages to DLQ" end)

    opts = Enum.into(state, [])

    dead_letters =
      Enum.map(messages, fn {og, reason} ->
        Keyword.merge(opts, reason: reason, original_message: og)
        |> DeadLetter.new()
      end)

    dlq().write(dead_letters)
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:EXIT, pid, reason}, %{elsa_pid: pid} = state) do
    Logger.error(fn -> "#{__MODULE__}: Elsa(#{inspect(pid)}) died : #{inspect(reason)}" end)
    {:stop, reason, state}
  end

  def handle_info(message, state) do
    Logger.info(fn -> "#{__MODULE__}: received unknown message - #{inspect(message)}" end)
    {:noreply, state}
  end

  @impl GenServer
  def terminate(reason, %{elsa_pid: pid}) do
    Process.exit(pid, reason)

    receive do
      {:EXIT, ^pid, _} -> reason
    after
      20_000 -> reason
    end
  end

  def terminate(reason, _) do
    reason
  end

  defp start_producer(topic, conn) do
    with {:ok, pid} <-
           Elsa.Supervisor.start_link(
             connection: conn,
             endpoints: topic.endpoints,
             producer: [
               topic: topic.name
             ]
           ),
         true <- Elsa.Producer.ready?(conn) do
      Ok.ok(pid)
    end
  end

  defp do_write(topic, messages) do
    connection(topic)
    |> Ok.map(&Elsa.produce(&1, topic.name, messages, [partitioner: topic.partitioner]))
  end

  @retry with: constant_backoff(100) |> take(10)
  defp connection(topic) do
    table_name(topic)
    |> :ets.lookup_element(topic.pid, 2)
    |> Ok.ok()
  catch
    _, reason ->
      Ok.error(reason)
  end

  defp store_connection(topic, connection) do
    table = table_name(topic)

    case :ets.whereis(table) do
      :undefined -> :ets.new(table, [:named_table, :protected])
      _ -> :ok
    end

    :ets.insert(table, {self(), connection})
  end

  defp table_name(topic) do
    :"destination_kafka_#{topic.name}"
  end

  defp connection_name do
    :"#{__MODULE__}_#{inspect(self())}"
  end

  defp key(%{key_path: []}, _), do: ""

  defp key(%{key_path: path}, message) do
    get_in(message, path) || ""
  end
end

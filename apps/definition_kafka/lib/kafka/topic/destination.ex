defmodule Kafka.Topic.Destination do
  use GenServer
  require Logger

  @spec start_link(Destination.t(), Dictionary.t()) :: {:ok, Destination.t()} | {:error, term}
  def start_link(dest, _dictionary) do
    GenServer.start_link(__MODULE__, dest)
    |> Ok.map(&Map.put(dest, :pid, &1))
  end

  # TODO
  def write(_dest, _dictionary, _messages) do
    :ok
  end

  # TODO
  def stop(_t) do
    :ok
  end

  @spec delete(Destination.t()) :: :ok | {:error, term}
  def delete(dest) do
    with {:error, reason} <- Elsa.delete_topic(dest.endpoints, dest.topic),
         log_reason <- inspect(reason) do
      Logger.warn(fn -> "Topic '#{dest.topic}' failed to delete: #{log_reason}" end)
      Ok.error(reason)
    end
  end

  @impl GenServer
  def init(dest) do
    Process.flag(:trap_exit, true)
    state = %{destination: dest, connection: connection_name()}
    {:ok, state, {:continue, :init}}
  end

  @impl GenServer
  def handle_continue(:init, %{destination: dest} = state) do
    with opts <- Map.from_struct(dest) |> Enum.into([]),
         :ok <- Elsa.create_topic(dest.endpoints, dest.topic, opts),
         {:ok, _} <- start_producer(state) do
      {:noreply, state}
    end
  end

  defp start_producer(%{connection: conn, destination: dest}) do
    Elsa.Supervisor.start_link(
      connection: conn,
      endpoints: dest.endpoints,
      producer: [
        topic: dest.topic
      ]
    )
    |> Ok.map(fn _ -> Elsa.Producer.ready?(conn) end)
  end

  defp connection_name do
    :"#{__MODULE__}_#{inspect(self())}"
  end
end

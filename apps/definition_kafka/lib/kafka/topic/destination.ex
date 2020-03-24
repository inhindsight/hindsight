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
    {:ok, dest, {:continue, :init}}
  end

  @impl GenServer
  def handle_continue(:init, dest) do
    with opts <- Map.from_struct(dest) |> Enum.into([]),
         :ok <- Elsa.create_topic(dest.endpoints, dest.topic, opts) do
      {:noreply, dest}
    end
  end
end

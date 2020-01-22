defmodule Broadcast.Stream.Broadway do
  use Broadway
  use Properties, otp_app: :service_broadcast
  require Logger

  alias Writer.DLQ.DeadLetter
  alias BroadcastWeb.Endpoint
  alias Broadway.Message

  @app_name get_config_value(:app_name, required: true)

  getter(:broadway_config, required: true)
  getter(:dlq, default: Broadcast.DLQ)

  def start_link(init_arg) do
    %Load.Broadcast{} = load = Keyword.fetch!(init_arg, :load)
    Logger.debug(fn -> "#{__MODULE__}: Starting for #{inspect(load)}" end)

    config = setup_config(load)

    with {:ok, pid} <- Broadway.start_link(__MODULE__, config) do
      :"#{load.source}"
      |> Broadcast.Stream.Registry.register_name(pid)

      {:ok, pid}
    end
  end

  def handle_message(_processor, %Message{data: data} = message, %{load: load}) do
    Logger.debug(fn -> "#{__MODULE__}: Received message: #{inspect(message)}" end)

    with {:ok, decoded_value} <- Jason.decode(data.value) do
      Logger.debug(fn ->
        "#{__MODULE__}: Broadcasting to broadcast:#{load.destination}: #{inspect(decoded_value)}"
      end)

      Endpoint.broadcast!("broadcast:#{load.destination}", "update", decoded_value)
      message
    else
      {:error, reason} ->
        Message.update_data(message, &to_dead_letter(load, &1, reason))
        |> Message.failed(reason)
    end
  end

  def handle_failed(messages, _context) do
    messages
    |> Enum.map(fn message -> message.data end)
    |> dlq().write()

    messages
  end

  defp setup_config(load) do
    Keyword.put(broadway_config(), :name, :"broadcast_broadway_#{load.source}")
    |> Keyword.update!(:producer, &update_producer(load, &1))
    |> Keyword.put(:context, %{
      load: load
    })
  end

  defp update_producer(load, producer_config) do
    producer_config
    |> Keyword.update!(:module, fn {module, config} ->
      config =
        config
        |> Keyword.put(:connection, :"broadcast_connection_#{load.source}")
        |> Keyword.update(:group_consumer, [], fn group_consumer ->
          group_consumer
          |> Keyword.put(:group, "broadcast-#{load.source}")
          |> Keyword.put(:topics, [load.source])
        end)

      {module, config}
    end)
  end

  defp to_dead_letter(load, data, reason) do
    DeadLetter.new(
      dataset_id: load.dataset_id,
      original_message: data,
      app_name: @app_name,
      reason: reason
    )
  end
end

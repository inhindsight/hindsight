defmodule Broadcast.Stream.Broadway do
  use Broadway

  @config Application.get_env(:service_broadcast, __MODULE__, [])
  @broadway_config Keyword.fetch!(@config, :broadway_config)

  def start_link(init_arg) do
    %Load.Broadcast{} = load = Keyword.fetch!(init_arg, :load)

    config = setup_config(load)

    with {:ok, pid} <- Broadway.start_link(__MODULE__, config) do
      :"#{load.source}"
      |> Broadcast.Stream.Registry.register_name(pid)

      {:ok, pid}
    end
  end

  def handle_message(_processor, %Broadway.Message{data: data} = message, %{load: load}) do
    case Jason.decode(data.value) do
      {:ok, decoded_value} ->
        BroadcastWeb.Endpoint.broadcast!("broadcast:#{load.destination}", "update", decoded_value)
        message

      {:error, reason} ->
        Broadway.Message.failed(message, reason)
    end
  end

  defp setup_config(load) do
    Keyword.put(@broadway_config, :name, :"broadcast_broadway_#{load.source}")
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
end

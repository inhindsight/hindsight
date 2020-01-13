defmodule Broadcast.Stream.Broadway do
  use Broadway

  @config Application.get_env(:service_broadcast, __MODULE__, [])
  @broadway_config Keyword.fetch!(@config, :broadway_config)

  def start_link(args) do
    %Load.Broadcast{} = load = Keyword.fetch!(args, :load)

    config = setup_config(load)

    with {:ok, pid} <- Broadway.start_link(__MODULE__, config) do
      name(load)
      |> Broadcast.Stream.Registry.register_name(pid)

      {:ok, pid}
    end
  end

  def handle_message(_processor, %Broadway.Message{data: data} = message, _context) do
    case Jason.decode(data.value) do
      {:ok, decoded_value} ->
        BroadcastWeb.Endpoint.broadcast!("broadcast:#{data.topic}", "update", decoded_value)
        message

      {:error, reason} ->
        Broadway.Message.failed(message, reason)
    end
  end

  defp name(%Load.Broadcast{dataset_id: dataset_id, name: name}) do
    :"#{dataset_id}_#{name}"
  end

  defp setup_config(load) do
    name = name(load)

    Keyword.put(@broadway_config, :name, name)
    |> Keyword.update!(:producer, &update_producer(name, &1))
  end

  defp update_producer(name, producer_config) do
    producer_config
    |> Keyword.update!(:module, fn {module, config} ->
      config =
        config
        |> Keyword.put(:connection, :"connection_#{name}")
        |> Keyword.update(:group_consumer, [], fn group_consumer ->
          group_consumer
          |> Keyword.put(:group, "group-#{name}")
          |> Keyword.put(:topics, ["topic-#{name}"])
        end)

      {module, config}
    end)
  end
end

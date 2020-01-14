defmodule Persist.Load.Broadway do
  use Broadway

  alias Broadway.Message
  alias Writer.DLQ.DeadLetter

  @app_name Application.get_env(:service_persist, :app_name)

  @config Application.get_env(:service_persist, __MODULE__, [])
  @broadway_config Keyword.fetch!(@config, :broadway_config)
  @writer Keyword.get(@config, :writer, Persist.Writer)
  @dlq Keyword.get(@config, :dlq, Persist.DLQ)

  def start_link(init_arg) do
    %Load.Persist{} = load = Keyword.fetch!(init_arg, :load)
    # TODO move this to another process
    {:ok, writer} = @writer.start_link(load: load)

    config = setup_config(load, writer)

    with {:ok, pid} <- Broadway.start_link(__MODULE__, config) do
      Persist.Load.Registry.register_name(:"#{load.source}", pid)
      {:ok, pid}
    end
  end

  def handle_message(_processor, %Message{data: data} = message, context) do
    case Jason.decode(data.value) do
      {:ok, decoded_data} ->
        Message.update_data(message, fn _ -> decoded_data end)

      {:error, reason} ->
        Message.update_data(message, &to_dead_letter(context.load, &1, reason))
        |> Message.failed(reason)
    end
  end

  def handle_batch(_batch, messages, _info, context) do
    data_messages = Enum.map(messages, &Map.get(&1, :data))
    :ok = @writer.write(context.writer, data_messages)
    messages
  end

  def handle_failed(messages, _context) do
    messages
    |> Enum.map(&Map.get(&1, :data))
    |> @dlq.write()

    messages
  end

  defp to_dead_letter(load, data, reason) do
    DeadLetter.new(
      dataset_id: load.dataset_id,
      original_message: data,
      app_name: @app_name,
      reason: reason
    )
  end

  defp setup_config(load, writer) do
    Keyword.put(@broadway_config, :name, :"persist_broadway_#{load.source}")
    |> Keyword.update!(:producer, &update_producer(load, &1))
    |> Keyword.put(:context, %{
      load: load,
      writer: writer
    })
  end

  defp update_producer(load, producer_config) do
    producer_config
    |> Keyword.update!(:module, fn {module, config} ->
      config =
        config
        |> Keyword.put(:connection, :"persist_connection_#{load.source}")
        |> Keyword.update(:group_consumer, [], fn group_consumer ->
          group_consumer
          |> Keyword.put(:group, "persist-#{load.source}")
          |> Keyword.put(:topics, [load.source])
        end)

      {module, config}
    end)
  end
end

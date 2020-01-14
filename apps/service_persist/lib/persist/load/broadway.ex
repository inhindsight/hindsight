defmodule Persist.Load.Broadway do
  use Broadway

  alias Broadway.Message
  alias Writer.DLQ.DeadLetter

  @app_name Application.get_env(:service_persist, :app_name)

  @config Application.get_env(:service_persist, __MODULE__, [])
  @broadway_config Keyword.fetch!(@config, :broadway_config)
  @dlq Keyword.get(@config, :dlq, Persist.DLQ)

  @type init_opts :: [
    load: %Load.Persist{},
    writer: (list -> :ok | {:error, term})
  ]

  @spec start_link(init_opts) :: GenServer.on_start()
  def start_link(init_arg) do
    IO.puts("Broadway start_link")
    %Load.Persist{} = load = Keyword.fetch!(init_arg, :load)
    writer = Keyword.fetch!(init_arg, :writer)

    config = setup_config(load, writer)

    with {:ok, pid} <- Broadway.start_link(__MODULE__, config) do
      Persist.Load.Registry.register_name(:"#{load.source}", pid)
      {:ok, pid}
    end
  end

  @impl Broadway
  def handle_message(_processor, %Message{data: data} = message, context) do
    case Jason.decode(data.value) do
      {:ok, decoded_data} ->
        Message.update_data(message, fn _ -> decoded_data end)

      {:error, reason} ->
        Message.update_data(message, &to_dead_letter(context.load, &1, reason))
        |> Message.failed(reason)
    end
  end

  @impl Broadway
  def handle_batch(_batch, messages, _info, context) do
    data_messages = Enum.map(messages, &Map.get(&1, :data))
    :ok = context.writer.(data_messages)
    messages
  end

  @impl Broadway
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

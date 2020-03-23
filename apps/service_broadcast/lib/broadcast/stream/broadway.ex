defmodule Broadcast.Stream.Broadway do
  use Broadway
  use Properties, otp_app: :service_broadcast
  require Logger

  alias Dlq.DeadLetter
  alias BroadcastWeb.Endpoint
  alias Broadway.Message

  @app_name get_config_value(:app_name, required: true)

  getter(:dlq, default: Dlq)
  getter(:configuration, default: Broadcast.Stream.Broadway.Configuration)

  @type init_opts :: [
          load: Load.Broadcast.t()
        ]

  @spec start_link(init_opts) :: GenServer.on_start()
  def start_link(init_arg) do
    %Load.Broadcast{} = load = Keyword.fetch!(init_arg, :load)
    Logger.debug(fn -> "#{__MODULE__}: Starting for #{inspect(load)}" end)

    with {:ok, transformer} <- create_transformer(load.dataset_id, load.subset_id),
         {:ok, config} <-
           configuration().configure([], %{
             load: load,
             transformer: transformer,
             cache: Broadcast.Cache.Registry.via(load.destination)
           }),
         {:ok, pid} <- Broadway.start_link(__MODULE__, config) do
      :"#{load.source}"
      |> Broadcast.Stream.Registry.register_name(pid)

      {:ok, pid}
    end
  end

  def handle_message(_processor, %Message{data: data} = message, %{
        load: load,
        transformer: transformer
      }) do
    Logger.debug(fn -> "#{__MODULE__}: Received message: #{inspect(message)}" end)

    with {:ok, decoded_value} <- Jason.decode(data.value),
         {:ok, transformed_value} <- transformer.(decoded_value) do
      Logger.debug(fn ->
        "#{__MODULE__}: Broadcasting to broadcast:#{load.destination}: #{inspect(decoded_value)}"
      end)

      Endpoint.broadcast!("broadcast:#{load.destination}", "update", transformed_value)
      Broadway.Message.update_data(message, &Map.put(&1, :value, transformed_value))
    else
      {:error, reason} -> Message.failed(message, reason)
    end
  end

  def handle_failed(messages, context) do
    messages
    |> Enum.map(&to_dead_letter(context.load, &1.data, &1.status))
    |> dlq().write()

    messages
  end

  def handle_batch(_batcher, messages, _batch_info, context) do
    data = Enum.map(messages, &Map.get(&1, :data)) |> Enum.map(&Map.get(&1, :value))

    unless context.load.cache == 0 do
      Broadcast.Cache.add(context.cache, data)
    end

    messages
  end

  defp create_transformer(dataset_id, subset_id) do
    case Broadcast.Transformations.get(dataset_id, subset_id) do
      {:ok, nil} ->
        fn x -> Ok.ok(x) end |> Ok.ok()

      {:ok, transform} ->
        Transformer.create(transform.steps, transform.dictionary)

      result ->
        result
    end
  end

  defp to_dead_letter(load, data, reason) do
    DeadLetter.new(
      dataset_id: load.dataset_id,
      subset_id: load.subset_id,
      original_message: data,
      app_name: @app_name,
      reason: reason
    )
  end
end

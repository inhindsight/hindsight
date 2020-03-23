defmodule Persist.Load.Broadway do
  use Broadway
  use Properties, otp_app: :service_persist
  require Logger

  alias Broadway.Message
  alias Dlq.DeadLetter

  @app_name get_config_value(:app_name, required: true)

  getter(:dlq, default: Dlq)
  getter(:configuration, default: Persist.Load.Broadway.Configuration)

  @type init_opts :: [
          load: Load.Persist.t(),
          transform: Transform.t(),
          writer: (list -> :ok | {:error, term})
        ]

  @spec start_link(init_opts) :: GenServer.on_start()
  def start_link(init_arg) do
    Logger.debug(fn ->
      "#{__MODULE__}: start_link is invoked with configuration #{configuration()}"
    end)

    %Load.Persist{} = load = Keyword.fetch!(init_arg, :load)
    transform = Keyword.fetch!(init_arg, :transform)
    writer = Keyword.fetch!(init_arg, :writer)

    with {:ok, transformer} <- create_transformer(transform),
         {:ok, config} <-
           configuration().configure([], %{load: load, transformer: transformer, writer: writer}) do
      Logger.debug(fn ->
        "#{__MODULE__}: calling Broadway.start_link with config #{inspect(config, pretty: true)}"
      end)

      Broadway.start_link(__MODULE__, config)
    end
  end

  @impl Broadway
  def handle_message(_processor, %Message{data: data} = message, context) do
    Logger.debug(fn -> "#{__MODULE__}: handling message #{inspect(message)}" end)

    with {:ok, decoded_data} <- Jason.decode(data.value),
         {:ok, transformed_data} <- context.transformer.(decoded_data) do
      Message.update_data(message, fn _ -> transformed_data end)
    else
      {:error, reason} -> Message.failed(message, reason)
    end
  end

  @impl Broadway
  def handle_batch(_batch, messages, _info, context) do
    data_messages = Enum.map(messages, &Map.get(&1, :data))
    :ok = context.writer.(data_messages)
    messages
  end

  @impl Broadway
  def handle_failed(messages, context) do
    messages
    |> Enum.map(&to_dead_letter(context.load, &1.data, &1.status))
    |> dlq().write()

    messages
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

  defp create_transformer(transform) do
    Transformer.create(transform.steps, transform.dictionary)
  end
end

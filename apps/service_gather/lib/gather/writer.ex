defmodule Gather.Writer do
  @behaviour Writer
  use Properties, otp_app: :service_gather

  getter(:app_name, required: true)
  getter(:writer, default: Writer.Kafka.Topic)
  getter(:dlq, default: Gather.DLQ)
  getter(:kafka_endpoints, required: true)

  alias Writer.DLQ.DeadLetter
  require Logger

  @impl Writer
  def start_link(args) do
    %Extract{destination: destination} = Keyword.fetch!(args, :extract)

    writer_args = [
      endpoints: kafka_endpoints(),
      name: Keyword.get(args, :name, nil),
      topic: destination
    ]

    writer().start_link(writer_args)
  end

  @impl Writer
  def child_spec(args) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [args]}
    }
  end

  @impl Writer
  def write(server, messages, opts \\ []) do
    dataset_id = Keyword.fetch!(opts, :dataset_id)

    results =
      Enum.reduce(messages, %{ok: [], error: []}, fn message, acc ->
        case Jason.encode(message) do
          {:ok, json} -> Map.update!(acc, :ok, fn l -> [json | l] end)
          {:error, reason} -> Map.update!(acc, :error, fn l -> [{message, reason} | l] end)
        end
      end)

    with :ok <- forward(server, Enum.reverse(results.ok)) do
      dlq(dataset_id, Enum.reverse(results.error))
      :ok
    end
  end

  defp forward(_server, []), do: :ok

  defp forward(server, messages) do
    writer().write(server, messages)
  end

  defp dlq(_, []), do: :ok

  defp dlq(dataset_id, errors) do
    with dead_letters <- Enum.map(errors, &to_dead_letter(dataset_id, &1)),
         {:error, reason} <- dlq().write(dead_letters) do
      log_dlq_error(dead_letters, reason)
    end
  end

  defp to_dead_letter(dataset_id, {og, reason}) do
    DeadLetter.new(
      dataset_id: dataset_id,
      original_message: og,
      app_name: app_name(),
      reason: reason
    )
  end

  defp log_dlq_error(messages, reason) do
    message_output = Enum.map(messages, &inspect/1) |> Enum.join("\n")
    log = "Unable to send following messages to DLQ due to '#{reason}' :\n#{message_output}"
    Logger.warn(log)
  end
end

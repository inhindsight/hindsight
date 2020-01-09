defmodule Gather.Writer do
  @behaviour Writer

  @config Application.get_env(:service_gather, __MODULE__, [])

  @writer Keyword.get(@config, :writer, Writer.Kafka.Topic)
  @dlq Keyword.get(@config, :dlq, Gather.DLQ)
  @topic_prefix Application.fetch_env!(:service_gather, :topic_prefix)

  alias Writer.DLQ.DeadLetter
  require Logger

  @impl Writer
  def start_link(args) do
    %Extract{dataset_id: dataset_id, name: name} = Keyword.fetch!(args, :extract)

    writer_args = [
      endpoints: Application.fetch_env!(:service_gather, :kafka_endpoints),
      name: Keyword.get(args, :name, nil),
      topic: "#{@topic_prefix}-#{dataset_id}-#{name}"
    ]

    @writer.start_link(writer_args)
  end

  @impl Writer
  defdelegate child_spec(args), to: @writer

  @impl Writer
  def write(server, messages, _opts \\ []) do
    results =
      Enum.reduce(messages, %{ok: [], error: []}, fn message, acc ->
        case Jason.encode(message) do
          {:ok, json} -> Map.update!(acc, :ok, fn l -> [json | l] end)
          {:error, reason} -> Map.update!(acc, :error, fn l -> [{message, reason} | l] end)
        end
      end)

    with :ok <- forward(server, Enum.reverse(results.ok)) do
      dlq(Enum.reverse(results.error))
      :ok
    end
  end

  defp forward(_server, []), do: :ok

  defp forward(server, messages) do
    @writer.write(server, messages)
  end

  defp dlq([]), do: :ok

  defp dlq(errors) do
    with dead_letters <- Enum.map(errors, &to_dead_letter/1),
         {:error, reason} <- @dlq.write(dead_letters) do
      log_dlq_error(dead_letters, reason)
    end
  end

  defp to_dead_letter({%Data{dataset_id: dataset_id} = og, reason}) do
    DeadLetter.new(
      dataset_id: dataset_id,
      original_message: og,
      app_name: Application.get_env(:service_gather, :app_name),
      reason: reason
    )
  end

  defp log_dlq_error(messages, reason) do
    message_output = Enum.map(messages, &inspect/1) |> Enum.join("\n")
    log = "Unable to send following messages to DLQ due to '#{reason}' :\n#{message_output}"
    Logger.warn(log)
  end
end

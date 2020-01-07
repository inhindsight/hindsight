defmodule Writer.DLQ do
  @behaviour Writer

  @default_writer Writer.Kafka.Topic
  @writer Application.get_env(:writer_dlq, :writer, @default_writer)
  @default_topic "dead-letter-queue"

  defimpl Jason.Encoder, for: Tuple do
    def encode(value, opts) do
      value
      |> Tuple.to_list()
      |> Jason.Encode.list(opts)
    end
  end

  defmodule DeadLetter do
    @type t :: %__MODULE__{
            dataset_id: String.t(),
            original_message: term,
            app_name: String.Chars.t(),
            stacktrace: list,
            reason: Exception.t() | String.Chars.t(),
            timestamp: DateTime.t()
          }

    @enforce_keys [:dataset_id, :original_message, :app_name, :reason]
    defstruct [
      :dataset_id,
      :original_message,
      :app_name,
      :stacktrace,
      :reason,
      :timestamp
    ]
  end

  @impl Writer
  def start_link(args) do
    @writer.start_link(
      endpoints: Keyword.fetch!(args, :endpoints),
      topic: Keyword.get(args, :topic, @default_topic)
    )
  end

  @impl Writer
  def child_spec(args) do
    @writer.child_spec(args)
  end

  @impl Writer
  def write(server, dead_letters, opts \\ []) do
    messages = Enum.map(dead_letters, &format/1)
    @writer.write(server, messages, opts)
  end

  defp format(%DeadLetter{} = dead_letter) do
    %{
      "app_name" => dead_letter.app_name |> to_string(),
      "dataset_id" => dead_letter.dataset_id,
      "original_message" => dead_letter.original_message |> sanitize_message(),
      "reason" => dead_letter.reason |> format_exception(),
      "stacktrace" =>
        (dead_letter.stacktrace || get_stacktrace()) |> Exception.format_stacktrace(),
      "timestamp" => dead_letter.timestamp || DateTime.utc_now()
    }
    |> Jason.encode!()
  end

  defp sanitize_message(message) do
    case Jason.encode(message) do
      {:ok, _} -> message
      {:error, _} -> inspect(message)
    end
  end

  defp get_stacktrace() do
    {:current_stacktrace, trace} = Process.info(self(), :current_stacktrace)
    trace
  end

  defp format_exception(exception) do
    case Exception.exception?(exception) do
      true -> Exception.format(:error, exception)
      false -> to_string(exception)
    end
  end
end

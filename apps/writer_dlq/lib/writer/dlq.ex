defmodule Writer.DLQ do
  @behaviour Writer
  require Logger

  alias Writer.DLQ.DeadLetter

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

  defmacro __using__(opts) do
    name = Keyword.fetch!(opts, :name)

    quote do
      @behaviour Writer

      def start_link(args) do
        Keyword.put(args, :name, unquote(name))
        |> Writer.DLQ.start_link()
      end

      def child_spec(args) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, [args]}
        }
      end

      defdelegate write(server, messages, opts \\ []), to: Writer.DLQ

      def write(messages) do
        Writer.DLQ.write(unquote(name), messages)
      end
    end
  end

  @impl Writer
  def start_link(args) do
    IO.inspect(@writer, label: "DLQ Writer")
    @writer.start_link(
      endpoints: Keyword.fetch!(args, :endpoints),
      topic: Keyword.get(args, :topic, @default_topic),
      name: Keyword.get(args, :name, nil)
    )
  end

  @impl Writer
  def child_spec(args) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [args]}
    }
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

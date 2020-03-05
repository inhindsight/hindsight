defmodule Writer.DLQ do
  @behaviour Writer
  require Logger
  use Properties, otp_app: :writer_dlq

  @default_topic "dead-letter-queue"

  getter(:writer, default: Writer.Kafka.Topic)

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
    writer().start_link(
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
    messages = Enum.map(dead_letters, &Jason.encode!/1)
    writer().write(server, messages, opts)
  end
end

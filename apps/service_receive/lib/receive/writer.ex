defmodule Receive.Writer do
  @behaviour Writer
  use Properties, otp_app: :service_receive

  getter(:app_name, required: true)
  getter(:writer, default: Writer.Kafka.Topic)
  getter(:kafka_endpoints, required: true)

  require Logger

  @impl Writer
  def start_link(args) do
    %Accept{destination: destination} = Keyword.fetch!(args, :accept)

    writer_args = [
      endpoints: kafka_endpoints(),
      name: Keyword.get(args, :name, nil)
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
  end
end

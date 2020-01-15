defmodule Gather.Extraction do
  use GenServer, restart: :transient
  use Retry
  require Logger
  use Properties, otp_app: :service_gather

  @max_tries get_config_value(:max_tries, default: 10)
  @initial_delay get_config_value(:initial_delay, default: 500)
  getter(:writer, default: Gather.Writer)
  getter(:chunk_size, default: 100)

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl GenServer
  def init(args) do
    {:ok, Map.new(args), {:continue, :extract}}
  end

  @dialyzer {:nowarn_function, handle_continue: 2}
  @impl GenServer
  def handle_continue(:extract, %{extract: extract} = state) do
    retry with: exponential_backoff(@initial_delay) |> Stream.take(@max_tries) do
      with {:ok, writer} <- writer().start_link(extract: extract) do
        extract(writer, extract)
      end
    after
      :ok -> {:stop, :normal, state}
    else
      {:error, reason} -> {:stop, reason, state}
    end
  end

  defp extract(writer, extract) do
    with {:ok, stream} <- Extract.Steps.execute(extract.steps),
         {:error, reason} <- write(writer, stream) do
      warn_extract_failure(extract, reason)
      {:error, reason}
    end
  rescue
    e -> {:error, e}
  after
    Process.exit(writer, :normal)
  end

  defp write(writer, stream) do
    stream
    |> Stream.chunk_every(chunk_size())
    |> Ok.each(&writer().write(writer, &1))
  end

  defp warn_extract_failure(extract, reason) do
    Logger.warn(
      "#{__MODULE__}: Failed with reason: #{inspect(reason)}, extract: #{inspect(extract)}"
    )
  end
end

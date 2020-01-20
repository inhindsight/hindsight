defmodule Gather.Extraction do
  use GenServer, restart: :transient
  require Logger
  use Properties, otp_app: :service_gather
  use Annotated.Retry

  alias Extract.Steps.Context

  @max_tries get_config_value(:max_tries, default: 10)
  @initial_delay get_config_value(:initial_delay, default: 500)
  getter(:writer, default: Gather.Writer)
  getter(:chunk_size, default: 100)

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl GenServer
  def init(args) do
    Process.flag(:trap_exit, true)
    {:ok, Map.new(args), {:continue, :extract}}
  end

  @dialyzer {:nowarn_function, handle_continue: 2}
  @impl GenServer
  def handle_continue(:extract, %{extract: extract} = state) do
    Logger.debug(fn -> "#{__MODULE__}: Started extraction: #{inspect(extract)}" end)

    case extract(extract) do
      :ok ->
        {:stop, :normal, state}

      {:error, reason} ->
        Logger.warn("#{__MODULE__}: Extraction Stopping: #{inspect(extract)}")
        {:stop, reason, state}
    end
  end

  @retry with: exponential_backoff(@initial_delay) |> take(@max_tries)
  defp extract(extract) do
    with {:ok, writer} <- writer().start_link(extract: extract) do
      do_extract(writer, extract)
    end
  end

  defp do_extract(writer, extract) do
    with {:ok, context} <- Extract.Steps.execute(extract.steps),
         {:error, reason} <- write(writer, context, extract.dataset_id) do
      warn_extract_failure(extract, reason)
      {:error, reason}
    end
  rescue
    e -> {:error, e}
  after
    Process.exit(writer, :normal)
  end

  defp write(writer, context, dataset_id) do
    context
    |> Context.get_stream()
    |> Stream.chunk_every(chunk_size())
    |> Ok.each(fn chunk ->
      with :ok <- writer().write(writer, chunk, dataset_id: dataset_id) do
        Context.run_after_functions(context, chunk)
        :ok
      end
    end)
  end

  defp warn_extract_failure(extract, reason) do
    Logger.warn(
      "#{__MODULE__}: Failed with reason: #{inspect(reason)}, extract: #{inspect(extract)}"
    )
  end
end

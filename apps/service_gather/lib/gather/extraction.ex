defmodule Gather.Extraction do
  @moduledoc """
  Process to wrap and manage a dataset's extraction pipeline. This is operated
  like a `Task`, in that it executes and shuts down.
  """
  import Events
  use GenServer, restart: :transient
  require Logger
  use Properties, otp_app: :service_gather
  use Annotated.Retry

  @max_tries get_config_value(:max_tries, default: 10)
  @initial_delay get_config_value(:initial_delay, default: 500)
  getter(:dlq, default: Dlq)
  getter(:app_name, required: true)

  def start_link(args) do
    server_opts = Keyword.take(args, [:name])
    GenServer.start_link(__MODULE__, args, server_opts)
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
      {:ok, _destination_pid} ->
        Logger.debug(fn -> "#{__MODULE__}: Extraction Completed: #{inspect(extract)}" end)
        Brook.Event.send(Gather.Application.instance(), extract_end(), "gather", extract)
        {:stop, :normal, state}

      {:error, reason} ->
        Logger.warn("#{__MODULE__}: Extraction Stopping: #{inspect(extract)}")
        {:stop, reason, state}
    end
  end

  @retry with: exponential_backoff(@initial_delay) |> take(@max_tries)
  defp extract(extract) do
    with {:ok, pid} <- start_destination(extract),
         :ok <- do_extract(pid, extract) do
      {:ok, pid}
    end
  end

  defp start_destination(extract) do
    Destination.start_link(
      extract.destination,
      Destination.Context.new!(
        app_name: app_name(),
        dataset_id: extract.dataset_id,
        subset_id: extract.subset_id,
        dictionary: extract.dictionary
      )
    )
  end

  defp do_extract(destination_pid, extract) do
    Gather.Extraction.SourceStream.start_source(extract, destination_pid)
  rescue
    e ->
      warn_extract_failure(extract, e)
      {:error, e}
  after
    Destination.stop(extract.destination, destination_pid)
  end

  # defp decode(stream, extract) do
  #   Decoder.decode(extract.decoder, stream)
  # end

  defp warn_extract_failure(extract, reason) do
    Logger.warn(fn ->
      "#{__MODULE__}: Failed with reason: #{inspect(reason)}, extract: #{inspect(extract)}"
    end)

    reason
  end
end

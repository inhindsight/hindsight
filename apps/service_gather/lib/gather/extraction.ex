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
    case extract(extract) do
      {:ok, pid} ->
        Logger.debug(fn -> "#{__MODULE__}: Started extraction: #{inspect(extract)}" end)
        {:noreply, Map.put(state, :destination_pid, pid)}

      {:error, reason} ->
        Logger.warn("#{__MODULE__}: Extraction Stopping: #{inspect(extract)}")
        {:stop, reason, state}
    end
  end

  @impl GenServer
  def handle_info(:extract_complete, %{extract: extract, destination_pid: pid} = state) do
    Destination.stop(extract.destination, pid)

    Logger.debug(fn -> "#{__MODULE__}: Extraction Completed: #{inspect(extract)}" end)
    Brook.Event.send(Gather.Application.instance(), extract_end(), "gather", extract)

    {:stop, :normal, state}
  end

  @impl GenServer
  def handle_info({:extract_failed, reason}, %{extract: extract, destination_pid: pid} = state) do
    Destination.stop(extract.destination, pid)

    Logger.warn("#{__MODULE__}: Extraction Stopping: #{inspect(extract)}")
    {:stop, reason, state}
  end

  @impl GenServer
  def handle_info(msg, state) do
    Logger.info(fn -> "Received message : #{inspect(msg)}" end)
    {:noreply, state}
  end

  @retry with: exponential_backoff(@initial_delay) |> take(@max_tries)
  defp extract(extract) do
    with {:ok, pid} <- start_destination(extract),
         :ok <- Gather.Extraction.SourceStream.start_source(extract, pid) do
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
end

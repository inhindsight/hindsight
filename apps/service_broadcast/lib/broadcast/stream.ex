defmodule Broadcast.Stream do
  use GenServer, shutdown: 30_000
  use Annotated.Retry
  use Properties, otp_app: :service_broadcast
  require Logger

  alias Broadcast.Transformations

  import Definition, only: [identifier: 1]

  @max_retries get_config_value(:max_retries, default: 50)

  @type init_opts :: [
          load: Load.Broadcast.t()
        ]

  def start_link(init_opts) do
    server_opts = Keyword.take(init_opts, [:name])
    GenServer.start_link(__MODULE__, init_opts, server_opts)
  end

  @impl GenServer
  def init(init_opts) do
    Process.flag(:trap_exit, true)
    Logger.debug(fn -> "#{__MODULE__}: init with #{inspect(init_opts)}" end)

    state = %{
      load: Keyword.fetch!(init_opts, :load)
    }

    {:ok, state, {:continue, :init}}
  end

  @impl GenServer
  def handle_continue(:init, state) do
    with {:ok, transform} when transform != nil <-
           Transformations.get(state.load.dataset_id, state.load.subset_id),
         {:ok, dictionary} <-
           Transformer.transform_dictionary(transform.steps, transform.dictionary),
         {:ok, transformer} <- Transformer.create(transform.steps, transform.dictionary),
         {:ok, cache_pid} <- start_cache(state.load),
         {:ok, source_pid} <- start_source(state.load, dictionary, transformer) do
      new_state =
        state
        |> Map.put(:cache_pid, cache_pid)
        |> Map.put(:source_pid, source_pid)

      {:noreply, new_state}
    else
      {:ok, nil} ->
        Logger.error(fn ->
          "#{__MODULE__}: Unable to find transformation for #{inspect(state.load)}"
        end)

        {:stop, "no transformation found", state}

      {:error, reason} ->
        {:stop, reason, state}
    end
  end

  @retry with: exponential_backoff(100) |> take(@max_retries)
  defp start_cache(load) do
    cache_name = Broadcast.Cache.Registry.via(identifier(load))
    Broadcast.Cache.start_link(name: cache_name, load: load)
  end

  @retry with: exponential_backoff(100) |> take(@max_retries)
  defp start_source(load, dictionary, transformer) do
    context =
      Source.Context.new!(
        dictionary: dictionary,
        handler: Broadcast.Stream.SourceHandler,
        app_name: :service_broadcast,
        dataset_id: load.dataset_id,
        subset_id: load.subset_id,
        assigns: %{
          load: load,
          transformer: transformer,
          cache: Broadcast.Cache.Registry.via(identifier(load)),
          kafka: %{
            offset_reset_policy: :reset_to_latest
          }
        }
      )

    Source.start_link(load.source, context)
  end

  @impl GenServer
  def terminate(reason, state) do
    if Map.has_key?(state, :cache_pid) do
      Map.get(state, :cache_pid) |> kill(reason)
    end

    if Map.has_key?(state, :source) do
      pid = Map.get(state, :source_pid)
      Source.stop(state.load.source, pid)
    end

    reason
  end

  defp kill(pid, reason) do
    Process.exit(pid, reason)

    receive do
      {:EXIT, ^pid, _} ->
        :ok
    after
      20_000 -> :ok
    end
  end
end

defmodule Persist.Loader do
  use GenServer, shutdown: 30_000
  use Annotated.Retry
  use Properties, otp_app: :service_persist
  require Logger

  @max_retries get_config_value(:max_retries, default: 10)

  alias Persist.Transformations

  @type init_opts :: [
          load: %Load{}
        ]

  @spec start_link(init_opts) :: GenServer.on_start()
  def start_link(init_arg) do
    server_opts = Keyword.take(init_arg, [:name])
    GenServer.start_link(__MODULE__, init_arg, server_opts)
  end

  @impl GenServer
  def init(init_arg) do
    Process.flag(:trap_exit, true)
    %Load{} = load = Keyword.fetch!(init_arg, :load)
    Logger.debug(fn -> "#{__MODULE__}:#{inspect(self())} initializied for #{inspect(load)}" end)

    with {:ok, transform} when not is_nil(transform) <-
           Transformations.get(load.dataset_id, load.subset_id),
         {:ok, dictionary} <- transform_dictionary(transform),
         {:ok, destination_pid} <- start_destination(load, dictionary),
         {:ok, source_pid} <- start_source(load, dictionary, transform, destination_pid) do
      {:ok, %{load: load, destination_pid: destination_pid, source_pid: source_pid}}
    else
      {:ok, nil} ->
        Logger.warn(fn ->
          "#{__MODULE__}: Stopping : Unable to find transformation for dataset #{load.dataset_id}"
        end)

        {:stop, "unable to find transformation for dataset #{load.dataset_id}"}

      {:error, reason} ->
        Logger.warn(fn -> "#{__MODULE__}: Stopping : #{inspect(reason)}" end)
        {:stop, reason}
    end
  end

  @impl GenServer
  def handle_info({:EXIT, pid, reason}, state) do
    Logger.warn(fn ->
      "#{__MODULE__}: Stopping due to exit from pid(#{inspect(pid)}) : reason #{inspect(reason)} : state #{
        inspect(state, pretty: true)
      }"
    end)

    Source.stop(state.load.source, state.source_pid)
    Destination.stop(state.load.destination, state.destination_pid)
    {:stop, reason, state}
  end

  defp transform_dictionary(transform) do
    Transformer.transform_dictionary(transform.steps, transform.dictionary)
  end

  @retry with: exponential_backoff(100) |> take(@max_retries)
  defp start_source(load, dictionary, transform, destination_pid) do
    with {:ok, transformer} <- create_transformer(transform) do
      context =
        Source.Context.new!(
          dictionary: dictionary,
          handler: Persist.Load.SourceHandler,
          app_name: :service_persist,
          dataset_id: load.dataset_id,
          subset_id: load.subset_id,
          assigns: %{
            transformer: transformer,
            destination: load.destination,
            destination_pid: destination_pid
          }
        )

      Source.start_link(load.source, context)
    end
  end

  @retry with: exponential_backoff(100) |> take(@max_retries)
  defp start_destination(load, dictionary) do
    context =
      Destination.Context.new!(
        dictionary: dictionary,
        app_name: :service_persist,
        dataset_id: load.dataset_id,
        subset_id: load.subset_id
      )

    Destination.start_link(load.destination, context)
  end

  defp create_transformer(transform) do
    Transformer.create(transform.steps, transform.dictionary)
  end
end

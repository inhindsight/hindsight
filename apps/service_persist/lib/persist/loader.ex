defmodule Persist.Loader do
  use GenServer, shutdown: 30_000
  use Annotated.Retry
  use Properties, otp_app: :service_persist
  require Logger

  @max_retries get_config_value(:max_retries, default: 10)

  alias Persist.Transformations

  getter(:writer, default: Persist.Writer.TwoStep)

  @type init_opts :: [
          load: %Load.Persist{}
        ]

  @spec start_link(init_opts) :: GenServer.on_start()
  def start_link(init_arg) do
    server_opts = Keyword.take(init_arg, [:name])
    GenServer.start_link(__MODULE__, init_arg, server_opts)
  end

  @impl GenServer
  def init(init_arg) do
    Process.flag(:trap_exit, true)
    %Load.Persist{} = load = Keyword.fetch!(init_arg, :load)
    Logger.debug(fn -> "#{__MODULE__}:#{inspect(self())} initializied for #{inspect(load)}" end)

    with {:ok, transform} when not is_nil(transform) <-
           Transformations.get(load.dataset_id, load.subset_id),
         {:ok, dictionary} <- transform_dictionary(transform),
         {:ok, writer_pid} <- start_writer(load, dictionary),
         writer_function <- fn msgs ->
           writer().write(writer_pid, msgs, dictionary: dictionary)
         end,
         {:ok, source_pid} <- start_source(load, dictionary, transform, writer_function) do
      {:ok, %{load: load, writer_pid: writer_pid, source_pid: source_pid}}
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
    stop(state.writer_pid, reason)
    {:stop, reason, state}
  end

  defp transform_dictionary(transform) do
    Transformer.transform_dictionary(transform.steps, transform.dictionary)
  end

  @retry with: exponential_backoff(100) |> take(@max_retries)
  defp start_writer(load, dictionary) do
    writer().start_link(load: load, dictionary: dictionary)
  end

  @retry with: exponential_backoff(100) |> take(@max_retries)
  defp start_source(load, dictionary, transform, writer) do
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
            writer: writer
          }
        )

      Source.start_link(load.source, context)
    end
  end

  defp create_transformer(transform) do
    Transformer.create(transform.steps, transform.dictionary)
  end

  defp stop(nil, _), do: :ok

  defp stop(pid, reason) do
    case Process.alive?(pid) do
      true ->
        Process.exit(pid, reason)

        receive do
          {:EXIT, ^pid, _} -> :ok
        after
          30_000 -> Logger.warn(fn -> "#{__MODULE__}: unable to kill #{inspect(pid)}" end)
        end

      false ->
        :ok
    end
  end
end

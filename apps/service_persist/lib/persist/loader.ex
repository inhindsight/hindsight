defmodule Persist.Loader do
  use GenServer
  use Annotated.Retry
  use Properties, otp_app: :service_persist
  require Logger

  @max_retries get_config_value(:max_retries, default: 10)

  alias Persist.Transformations

  getter(:writer, default: Persist.Writer.TwoStep)
  getter(:broadway, default: Persist.Load.Broadway)

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
    Logger.debug(fn -> "#{__MODULE__}: initializied for #{inspect(load)}" end)

    with {:ok, transform} when not is_nil(transform) <-
           Transformations.get(load.dataset_id, load.subset_id),
         {:ok, dictionary} <- transform_dictionary(transform),
         {:ok, writer_pid} <- start_writer(load, dictionary),
         writer_function <- fn msgs ->
           writer().write(writer_pid, msgs, dictionary: dictionary)
         end,
         {:ok, broadway_pid} <- start_broadway(load, transform, writer_function) do
      {:ok, %{writer_pid: writer_pid, broadway_pid: broadway_pid}}
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
  def handle_info({:EXIT, _pid, reason}, state) do
    Logger.warn(fn -> "#{__MODULE__}: Stopping : #{inspect(reason)}" end)
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
  defp start_broadway(load, transform, writer) do
    broadway().start_link(load: load, transform: transform, writer: writer)
  end
end

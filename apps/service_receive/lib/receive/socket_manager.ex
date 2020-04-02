defmodule Receive.SocketManager do
  use GenServer
  use Annotated.Retry
  use Properties, otp_app: :service_receive
  import Definition, only: [identifier: 1]
  require Logger

  @max_retries get_config_value(:max_retries, default: 10)
  getter(:batch_size, default: 1_000)
  getter(:timeout, default: 1_000)
  getter(:app_name, default: true)

  def start_link(args) do
    %Accept{} = accept = Keyword.fetch!(args, :accept)
    name = Receive.Accept.Registry.via(:"#{identifier(accept)}_manager")

    GenServer.start_link(__MODULE__, args, name: name)
  end

  @impl GenServer
  def init(args) do
    Process.flag(:trap_exit, true)
    %Accept{} = accept = Keyword.fetch!(args, :accept)
    Logger.debug(fn -> "#{__MODULE__}: initialized for #{inspect(accept)}" end)

    with {:ok, context} <- destination_context(accept),
         {:ok, destination} <- Destination.start_link(accept.destination, context),
         {:ok, socket_pid} <- start_socket(%{accept | destination: destination}) do
      Ok.ok(%{destination: destination, socket_pid: socket_pid})
    else
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

  @retry with: exponential_backoff(100) |> take(@max_retries)
  defp start_socket(accept) do
    {mod, fun, args} =
      Accept.Connection.connect(
        accept.connection,
        writer: &Destination.write(accept.destination, &1),
        batch_size: batch_size(),
        timeout: timeout(),
        name: Receive.Accept.Registry.via(:"#{identifier(accept)}_socket")
      )

    apply(mod, fun, [args])
  end

  @retry with: exponential_backoff(100) |> take(@max_retries)
  defp start_socket(accept, writer) do
    {socket_module, start_function, args} =
      Accept.Connection.connect(
        accept.connection,
        writer: writer,
        batch_size: batch_size(),
        timeout: timeout(),
        name: Receive.Accept.Registry.via(:"#{identifier(accept)}_socket")
      )

    apply(socket_module, start_function, [args])
  end

  defp destination_context(accept) do
    Destination.Context.new(
      dictionary: Dictionary.from_list([]),
      app_name: app_name(),
      dataset_id: accept.dataset_id,
      subset_id: accept.subset_id
    )
  end
end

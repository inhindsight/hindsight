defmodule Receive.SocketManager do
  use GenServer
  use Annotated.Retry
  use Properties, otp_app: :service_receive
  require Logger

  @max_retries get_config_value(:max_retries, default: 10)
  getter(:writer, default: Receive.Writer)
  getter(:batch_size, default: 1_000)
  getter(:timeout, default: 1_000)

  def start_link(args) do
    name = :"#{args.dataset_id}_#{args.subset_id}_manager"

    GenServer.start_link(__MODULE__, args, name: name)
  end

  @impl GenServer
  def init(args) do
    Process.flag(:trap_exit, true)
    %Accept.Udp{} = accept = Keyword.fetch!(args, :accept)
    Logger.debug(fn -> "#{__MODULE__}: initialized for #{inspect(accept)}" end)

    with {:ok, writer_pid} <- start_writer(accept),
         writer_function <- fn msgs ->
           writer().write(writer_pid, msgs, accept: accept)
         end,
         {:ok, socket_pid} <- start_socket(accept, writer_function) do
      {:ok, %{writer_pid: writer_pid, socket_pid: socket_pid}}
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
  defp start_writer(accept) do
    writer().start_link(accept: accept)
  end

  @retry with: exponential_backoff(100) |> take(@max_retries)
  defp start_socket(accept, writer) do
    {socket, start, args} =
      Accept.Connection.connect(
        accept,
        writer: writer,
        batch_size: batch_size(),
        timeout: timeout()
      )

    apply(socket, start, args)
  end
end

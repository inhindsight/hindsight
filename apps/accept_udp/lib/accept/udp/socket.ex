defmodule Accept.Udp.Socket do
  @moduledoc "TODO"

  @type init_opts :: Accept.Socket.init_opts()

  use GenServer
  use Accept.Socket
  require Logger

  @impl Accept.Socket
  def start_link(init_opts) do
    port = init_opts.connection.port
    name = Map.get(init_opts, :name, :"udp_#{port}_receiver")

    GenServer.start_link(__MODULE__, init_opts, name: name)
  end

  @impl GenServer
  def init(init_opts) do
    state = %{
      port: init_opts.connection.port,
      batch_size: init_opts.batch_size,
      writer: init_opts.writer,
      socket: nil,
      queue: [],
      last_send: :erlang.system_time(),
      timeout: init_opts.timeout
    }

    {:ok, socket} = :gen_udp.open(state.port, [:binary, active: state.batch_size])

    {:ok, %{state | socket: socket}, state.timeout}
  end

  @impl GenServer
  def handle_info({:udp, _, _, _, payload}, %{queue: queue, batch_size: size} = state)
      when batch_reached?(queue, size) do
    new_state = process_messages([payload | queue], state)

    :ok = :inet.setopts(state.socket, active: size)

    {:noreply, new_state, new_state.timeout}
  end

  @impl GenServer
  def handle_info({:udp, _, _, _, payload}, state) do
    {:noreply, %{state | queue: [payload | state.queue]}, state.timeout}
  end

  @impl GenServer
  def handle_info(:timeout, %{queue: queue} = state) do
    case length(queue) do
      0 ->
        {:noreply, state}
      num ->
        new_state = process_messages(queue, state)
        :ok = :inet.setopts(state.socket, active: state.batch_size - num)

        {:noreply, new_state}
    end
  end

  @impl GenServer
  def handle_info(message, state) do
    Logger.debug("Socket received unexpected message : #{inspect(message)}")

    {:noreply, state}
  end

  defp process_messages(messages, state) do
    messages
    |> Enum.reverse()
    |> handle_messages(state.writer)

    state
    |> Map.put(:queue, [])
    |> Map.put(:last_send, :erlang.system_time())
  end
end

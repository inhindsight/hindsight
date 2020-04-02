defmodule Accept.Udp.Socket do
  @moduledoc "TODO"

  use GenServer
  use Accept.Socket
  require Logger

  @spec start_link(init_opts :: keyword) :: GenServer.on_start()
  def start_link(init_opts) do
    server_opts = Keyword.take(init_opts, [:name])

    GenServer.start_link(__MODULE__, init_opts, server_opts)
  end

  @impl GenServer
  def init(init_opts) do
    state = %{
      port: Keyword.fetch!(init_opts, :port),
      batch_size: Keyword.fetch!(init_opts, :batch_size),
      timeout: Keyword.fetch!(init_opts, :timeout),
      writer: Keyword.fetch!(init_opts, :writer),
      queue: []
    }

    {:ok, socket} = :gen_udp.open(state.port, [:binary, active: state.batch_size])
    Logger.debug(fn -> "#{__MODULE__}: Opened socket #{inspect(socket)}" end)

    {:ok, Map.put(state, :socket, socket), state.timeout}
  end

  @impl GenServer
  def handle_info({:udp, _, _, _, payload}, %{queue: queue, batch_size: size} = state)
      when batch_reached?(queue, size) do
    Logger.debug(fn -> "#{__MODULE__}: Batch reached" end)
    process_messages([payload | queue], state)

    :ok = :inet.setopts(state.socket, active: size)

    {:noreply, %{state | queue: []}, state.timeout}
  end

  @impl GenServer
  def handle_info({:udp, _, _, _, payload}, state) do
    Logger.debug(fn -> "#{__MODULE__}: Payload added to batch" end)
    {:noreply, %{state | queue: [payload | state.queue]}, state.timeout}
  end

  @impl GenServer
  def handle_info(:timeout, %{queue: queue} = state) do
    case length(queue) do
      0 ->
        Logger.debug(fn -> "#{__MODULE__}: Timeout reached without batch" end)
        {:noreply, state}

      num ->
        Logger.debug(fn -> "#{__MODULE__}: Timeout reached with batch of #{num} messages" end)
        process_messages(queue, state)
        :ok = :inet.setopts(state.socket, active: state.batch_size - num)

        {:noreply, %{state | queue: []}}
    end
  end

  @impl GenServer
  def handle_info(message, state) do
    Logger.debug("Socket received unexpected message : #{inspect(message)}")

    {:noreply, state}
  end

  defp process_messages(messages, state) do
    Logger.debug(fn ->
      "#{__MODULE__}: Writing #{Enum.count(messages)} to #{inspect(state.writer)}"
    end)

    messages
    |> Enum.reverse()
    |> handle_messages(state.writer)
  end
end

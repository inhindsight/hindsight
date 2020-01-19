defmodule Kafka.Subscribe.Acknowledger do
  use GenServer

  @type init_opts :: [
    connection: atom
  ]

  @spec cache(GenServer.server(), [%Elsa.Message{}]) :: :ok
  def cache(server, messages) do
    GenServer.cast(server, {:cache, messages})
  end

  @spec ack(GenServer.server(), list) :: :ok
  def ack(server, values) do
    GenServer.call(server, {:ack, values})
  end

  @spec start_link(init_opts) :: GenServer.on_start()
  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg)
  end

  @impl GenServer
  def init(init_arg) do
    Process.flag(:trap_exit, true)

    {:ok,
     %{
       connection: Keyword.fetch!(init_arg, :connection),
       table: :ets.new(nil, [:protected])
     }}
  end

  @impl GenServer
  def handle_cast({:cache, messages}, state) do
    Enum.each(messages, fn message ->
      :ets.insert(state.table, {message.value, message})
    end)

    {:noreply, state}
  end

  @impl GenServer
  def handle_call({:ack, values}, _from, state) do
    max_offset_message = get_max_offset_message(state, values)
    Elsa.Group.Acknowledger.ack(state.connection, max_offset_message)
    {:reply, :ok, state}
  end

  defp get_max_offset_message(state, keys) do
    keys
    |> Enum.map(&get_and_delete_key(state.table, &1))
    |> Enum.reject(&is_nil/1)
    |> Enum.max_by(fn msg -> msg.offset end)
  end

  defp get_and_delete_key(table, key) do
    case :ets.lookup(table, key) do
      [{_, value}] ->
        :ets.delete(table, key)
        value

      _ ->
        nil
    end
  end
end

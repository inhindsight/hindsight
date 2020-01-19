defmodule Kafka.Subscribe.Acknowledger do
  use GenServer

  def cache(server, messages) do
    GenServer.cast(server, {:cache, messages})
  end

  def ack(server, values) do
    GenServer.call(server, {:ack, values})
  end

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg)
  end

  def init(init_arg) do
    Process.flag(:trap_exit, true)

    {:ok,
     %{
       connection: Keyword.fetch!(init_arg, :connection),
       table: :ets.new(nil, [:protected])
     }}
  end

  def handle_cast({:cache, messages}, state) do
    Enum.each(messages, fn message ->
      :ets.insert(state.table, {message.value, message})
    end)

    {:noreply, state}
  end

  def handle_call({:ack, values}, _from, state) do
    max_offset_message =
      values
      |> Enum.map(fn value ->
        case :ets.lookup(state.table, value) do
          [{_, message}] ->
            :ets.delete(state.table, value)
            message

          _ ->
            nil
        end
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.max_by(fn msg -> msg.offset end)

    Elsa.Group.Acknowledger.ack(state.connection, max_offset_message)
    {:reply, :ok, state}
  end
end

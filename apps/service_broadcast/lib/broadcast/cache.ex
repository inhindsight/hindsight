defmodule Broadcast.Cache do
  use GenServer
  use Properties, otp_app: :service_broadcast

  getter(:cache_reclaim, default: 0.5)

  @spec add(GenServer.server(), list) :: :ok
  def add(server, values) do
    GenServer.cast(server, {:add, values})
  end

  @spec get(GenServer.server()) :: list
  def get(server) do
    GenServer.call(server, :get)
  end

  def start_link(init_arg) do
    server_opts = Keyword.take(init_arg, [:name])
    GenServer.start_link(__MODULE__, init_arg, server_opts)
  end

  def init(init_arg) do
    Process.flag(:trap_exit, true)
    broadcast = Keyword.fetch!(init_arg, :load) |> Map.get(:destination)

    state = %{
      list: [],
      max: broadcast.cache,
      min: Float.ceil(cache_reclaim() * broadcast.cache) |> trunc(),
      reclaim: cache_reclaim()
    }

    {:ok, state}
  end

  def handle_cast({:add, values}, state) do
    new_list = (Enum.reverse(values) ++ state.list) |> trim(state.min, state.max)
    {:noreply, %{state | list: new_list}}
  end

  def handle_call(:get, _from, state) do
    {:reply, Enum.reverse(state.list), state}
  end

  defp trim(list, min, max) when length(list) > max do
    Enum.take(list, min)
  end

  defp trim(list, _, _), do: list
end

defmodule SimpleRegistry do
  use GenServer
  require Logger

  defmacro __using__(opts) do
    registry = Keyword.fetch!(opts, :name)
    quote do

      def start_link(args \\ []) do
        config = Keyword.put(args, :name, unquote(registry))
        SimpleRegistry.start_link(config)
      end

      def child_spec(init_arg) do
        %{
          id: unquote(registry),
          start: {__MODULE__, :start_link, []}
        }
      end

      def via(name) do
        SimpleRegistry.via(unquote(registry), name)
      end

      def register_name(key, pid) do
        SimpleRegistry.register_name({__MODULE__, key}, pid)
      end

      def whereis(key) do
        SimpleRegistry.whereis_name({__MODULE__, key})
      end

      def registered_processes() do
        SimpleRegistry.registered_processes(unquote(registry))
      end

    end
  end

  @spec via(registry, key) :: {:via, __MODULE__, {registry, key}} when registry: atom, key: term
  def via(registry, key) do
    {:via, __MODULE__, {registry, key}}
  end

  @spec whereis_name({atom, term}) :: pid | :undefined
  def whereis_name({registry, key}) do
    whereis(table(registry), key)
  end

  @spec register_name({atom, term}, pid) :: :yes | :no
  def register_name({registry, key}, pid) do
    GenServer.call(registry, {:register, key, pid})
  end

  @spec unregister_name({atom, term}) :: :ok
  def unregister_name({registry, key}) do
    GenServer.call(registry, {:unregister, key})
  end

  @spec registered_processes(atom) :: list
  def registered_processes(registry) do
    :ets.match(table(registry), {:"$1", :"$2"})
    |> Enum.map(fn [key, pid] -> {key, pid} end)
  end

  @spec send({atom, term}, term) :: pid
  def send({registry, key}, message) do
    case whereis_name({registry, key}) do
      :undefined -> :erlang.error(:badarg, [{registry, key}, message])
      pid -> Kernel.send(pid, message)
    end
  end

  def start_link(args) do
    name = Keyword.fetch!(args, :name)
    GenServer.start_link(__MODULE__, args, name: name)
  end

  def init(args) do
    Process.flag(:trap_exit, true)

    table =
      Keyword.fetch!(args, :name)
      |> table()

    :ets.new(table, [:set, :named_table, :protected, {:read_concurrency, true}])

    {:ok, %{table: table}}
  end

  def handle_call({:register, key, pid}, _from, state) do
    case whereis(state.table, key) do
      :undefined ->
        Process.link(pid)
        :ets.insert(state.table, {key, pid})
        {:reply, :yes, state}

      _ ->
        {:reply, :no, state}
    end
  end

  def handle_call({:unregister, key}, _from, state) do
    case whereis(state.table, key) do
      :undefined ->
        :ok

      pid ->
        Process.unlink(pid)
        :ets.delete(state.table, key)
    end

    {:reply, :ok, state}
  end

  def handle_info({:EXIT, pid, _reason}, state) do
    case :ets.match(state.table, {:"$1", pid}) do
      [[key]] ->
        Logger.debug(fn ->
          "#{__MODULE__}: Removing key(#{inspect(key)}) and pid(#{inspect(pid)}))"
        end)

        :ets.delete(state.table, key)

      _ ->
        :ok
    end

    {:noreply, state}
  end

  defp whereis(table, key) do
    case :ets.lookup(table, key) do
      [] -> :undefined
      [{^key, pid}] -> pid
    end
  end

  defp table(name), do: :"#{__MODULE__}_#{name}"
end

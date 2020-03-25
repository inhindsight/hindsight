defmodule Define.ViewState do
  alias Define.{
    AppView,
    ModuleFunctionArgsView,
    ArgumentView,
    DataDefinitionView,
    ExtractView,
    Store
  }

  use GenServer

  def event(pid, type, payload) do
    GenServer.call(pid, {:event, type, payload})
  end

  def state(pid) do
    GenServer.call(pid, :state)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  def start_link(init_opts) do
    server_opts = Keyword.take(init_opts, [:name])
    GenServer.start_link(__MODULE__, default_state(), server_opts)
  end

  @impl true
  def handle_call({:event, type, payload}, _from, state) do
    new_state = update_state(state, type, payload)
    {:reply, new_state, new_state}
  end

  @impl true
  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  @spec default_state :: map()
  def default_state() do
    %AppView{
      greeting: "Hola Mundo!",
      data_definitions: Store.get_all()
    }
  end

  defp update_state(state, "new_greeting", payload) do
    Map.put(state, "greeting", Map.get(payload, "greeting"))
  end
end

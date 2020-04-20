defmodule Define.ViewState do
  alias Define.Model.AppView
  alias Define.Event.Store

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
  def handle_call({:event, _type, _payload}, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  @spec default_state :: map()
  def default_state() do
    %AppView{
      data_definitions: Store.get_all()
    }
  end
end

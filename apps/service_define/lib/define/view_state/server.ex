defmodule ViewState.Server do
  use GenServer

  @impl true
  def init(state) do
    {:ok, state}
  end

  def start_link(init_opts) do
    server_opts = Keyword.take(init_opts, [:name])
    GenServer.start_link(ViewState.Server, default_state(), [server_opts])
  end

  @impl true
  def handle_call({:event, event}, _from, state) do
    new_state = ViewState.event(state, event)
    {:reply, new_state, new_state}
  end

  @impl true
  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  def default_state() do
    %{ "greeting" => "Hola Mundo!" }
  end
end

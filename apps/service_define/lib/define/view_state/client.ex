defmodule ViewState.Client do

  def event(pid, event) do
    GenServer.call(pid, {:event, event})
  end

  def state(pid) do
    GenServer.call(pid, :state)
  end

end

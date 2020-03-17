defmodule ViewState.Client do

  def event(pid, event) do
    GenServer.call(pid, {:event, event})
  end

end

defmodule Profile.Test.Consumer do
  use GenStage

  def start_link(opts) do
    GenStage.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    pid = Keyword.fetch!(opts, :pid)
    {:consumer, pid}
  end

  def handle_events(events, _from, pid) do
    Enum.each(events, &send(pid, {:event, &1}))
    {:noreply, [], pid}
  end
end

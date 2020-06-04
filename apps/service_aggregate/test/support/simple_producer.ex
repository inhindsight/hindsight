defmodule Aggregate.Simple.Producer do
  use GenStage

  def inject_events(events, timeout \\ 5_000) do
    GenStage.call(__MODULE__, {:inject, events}, timeout)
  end

  def start_link(opts) do
    GenStage.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_) do
    {:producer, :ok}
  end

  def handle_call({:inject, events}, _from, state) do
    {:reply, :ok, events, state}
  end

  def handle_demand(_demand, state) do
    {:noreply, [], state}
  end
end

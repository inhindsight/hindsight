defmodule Dlq.Behaviour do
  @callback write([DeadLetter.t()]) :: :ok
end

defmodule Dlq do
  @behaviour Dlq.Behaviour

  @impl true
  def write(dead_letters) do
    GenServer.cast(Dlq.Server, {:write, dead_letters})
  end
end

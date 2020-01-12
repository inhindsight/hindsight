defmodule Broadcast.Init do
  use GenServer

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl GenServer
  def init(_init_arg) do
    start_streams()
    {:ok, %{}}
  end

  defp start_streams() do
    Broadcast.Stream.Store.get_all!()
    |> Enum.each(fn load ->
      Broadcast.Stream.Supervisor.start_child({Broadcast.Stream.Broadway, load: load})
    end)
  end
end

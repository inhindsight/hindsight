defmodule Broadcast.Init do
  use Initializer,
    name: __MODULE__,
    supervisor: Broadcast.Stream.Supervisor

  def on_start(state) do
    Broadcast.Stream.Store.get_all!()
    |> Enum.reject(&is_nil/1)
    |> Enum.each(fn load ->
      Broadcast.Stream.Supervisor.start_child({Broadcast.Stream, load: load})
    end)

    {:ok, state}
  end
end

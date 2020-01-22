defmodule Broadcast.Event.Handler do
  use Brook.Event.Handler
  require Logger

  import Events, only: [load_broadcast_start: 0, load_broadcast_end: 0]

  def handle_event(%Brook.Event{type: load_broadcast_start(), data: %Load.Broadcast{} = load}) do
    Logger.debug(fn ->
      "#{__MODULE__}: Received event #{load_broadcast_start()}: #{inspect(load)}"
    end)

    Broadcast.Stream.Supervisor.start_child({Broadcast.Stream.Broadway, load: load})
    Broadcast.Stream.Store.persist(load)
    :ok
  end

  def handle_event(%Brook.Event{type: load_broadcast_end(), data: %Load.Broadcast{} = load}) do
    case Broadcast.Stream.Registry.whereis(:"#{load.source}") do
      :undefined ->
        :ok

      pid ->
        Broadcast.Stream.Supervisor.terminate_child(pid)
        Broadcast.Stream.Store.delete(load.id)
        :ok
    end
  end
end

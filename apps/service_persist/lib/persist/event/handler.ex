defmodule Persist.Event.Handler do
  use Brook.Event.Handler
  require Logger

  import Events, only: [load_persist_start: 0, load_persist_end: 0, transform_define: 0]

  @impl Brook.Event.Handler
  def handle_event(%Brook.Event{type: load_persist_start(), data: %Load.Persist{} = load}) do
    Logger.debug(fn ->
      "#{__MODULE__}: Received event #{load_persist_start()}: #{inspect(load)}"
    end)

    Persist.Load.Supervisor.start_child({Persist.Loader, load: load})
    Persist.Load.Store.persist(load)
  end

  @impl Brook.Event.Handler
  def handle_event(%Brook.Event{type: load_persist_end(), data: %Load.Persist{} = load}) do
    case Persist.Load.Registry.whereis(:"#{load.source}") do
      :undefined ->
        :ok

      pid ->
        Persist.Load.Supervisor.terminate_child(pid)
        Persist.Load.Store.delete(load.dataset_id, load.subset_id)
    end
  end

  @impl Brook.Event.Handler
  def handle_event(%Brook.Event{type: transform_define(), data: %Transform{} = transform}) do
    Persist.Transformations.persist(transform)
  end
end

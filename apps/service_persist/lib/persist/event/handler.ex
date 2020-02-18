defmodule Persist.Event.Handler do
  use Brook.Event.Handler
  use Properties, otp_app: :service_persist
  require Logger

  import Events,
    only: [
      load_persist_start: 0,
      load_persist_end: 0,
      transform_define: 0,
      compact_start: 0,
      compact_end: 0
    ]

  @instance Persist.Application.instance()

  getter(:compactor, default: Persist.Compactor.Presto)

  @impl Brook.Event.Handler
  def handle_event(%Brook.Event{type: load_persist_start(), data: %Load.Persist{} = load}) do
    Logger.debug(fn ->
      "#{__MODULE__}: Received event #{load_persist_start()}: #{inspect(load)}"
    end)

    Persist.Load.Supervisor.start_child(load)
    Persist.Load.Store.persist(load)
  end

  @impl Brook.Event.Handler
  def handle_event(%Brook.Event{type: load_persist_end(), data: %Load.Persist{} = load}) do
    Logger.debug(fn ->
      "#{__MODULE__}: Received event #{load_persist_end()}: #{inspect(load)}"
    end)

    Persist.Load.Supervisor.terminate_child(load)
    Persist.Load.Store.mark_done(load)
    Events.send_compact_start(@instance, __MODULE__, load)
  end

  @impl Brook.Event.Handler
  def handle_event(%Brook.Event{type: transform_define(), data: %Transform{} = transform}) do
    Persist.Transformations.persist(transform)
  end

  @impl Brook.Event.Handler
  def handle_event(%Brook.Event{type: compact_start(), data: %Load.Persist{} = load}) do
    Persist.Load.Supervisor.terminate_child(load)

    Persist.Compact.Supervisor.start_child(load)
    Persist.Load.Store.mark_for_compaction(load)
  end

  @impl Brook.Event.Handler
  def handle_event(%Brook.Event{type: compact_end(), data: %Load.Persist{} = load}) do
    Persist.Load.Store.clear_compaction(load)

    case Persist.Load.Store.done?(load) do
      true -> Persist.Load.Store.delete(load.dataset_id, load.subset_id)
      false -> Persist.Load.Supervisor.start_child(load)
    end
  end
end

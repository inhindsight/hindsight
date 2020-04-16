defmodule Persist.Event.Handler do
  @moduledoc """
  Callbacks for handling events from `Brook`.
  """
  use Brook.Event.Handler
  use Properties, otp_app: :service_persist
  require Logger

  import Events,
    only: [
      load_start: 0,
      load_end: 0,
      transform_define: 0,
      compact_start: 0,
      compact_end: 0,
      dataset_delete: 0
    ]

  @instance Persist.Application.instance()

  getter(:compactor, default: Persist.Compactor.Presto)
  getter(:endpoints, required: true)

  @impl Brook.Event.Handler
  def handle_event(%Brook.Event{
        type: load_start(),
        data: %Load{destination: %Presto.Table{}} = load
      }) do
    Logger.debug(fn ->
      "#{__MODULE__}: Received event #{load_start()}: #{inspect(load)}"
    end)

    Persist.Load.Supervisor.start_child(load)
    Persist.Load.Store.persist(load)
  end

  @impl Brook.Event.Handler
  def handle_event(%Brook.Event{
        type: load_end(),
        data: %Load{destination: %Presto.Table{}} = load
      }) do
    Logger.debug(fn ->
      "#{__MODULE__}: Received event #{load_end()}: #{inspect(load)}"
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
  def handle_event(%Brook.Event{
        type: compact_start(),
        data: %Load{destination: %Presto.Table{}} = load
      }) do
    Persist.Load.Supervisor.terminate_child(load)

    Persist.Compact.Supervisor.start_child(load)
    Persist.Load.Store.mark_for_compaction(load)
  end

  @impl Brook.Event.Handler
  def handle_event(%Brook.Event{
        type: compact_end(),
        data: %Load{destination: %Presto.Table{}} = load
      }) do
    Persist.Load.Store.clear_compaction(load)

    case Persist.Load.Store.done?(load) do
      true -> :ok
      false -> Persist.Load.Supervisor.start_child(load)
    end
  end

  @impl Brook.Event.Handler
  def handle_event(%Brook.Event{type: dataset_delete(), data: %Delete{} = delete}) do
    Logger.debug(fn ->
      "#{__MODULE__}: Received event #{dataset_delete()}: #{inspect(delete)}"
    end)

    case Persist.Load.Store.get!(delete.dataset_id, delete.subset_id) do
      nil ->
        Logger.debug("No existing state to delete")
        nil

      load ->
        Persist.Compact.Supervisor.terminate_child(load)
        Persist.Load.Supervisor.terminate_child(load)
        Source.delete(load.source)
        Destination.delete(load.destination)
        Logger.debug("Deleted existing state")
    end

    Persist.Load.Store.delete(delete.dataset_id, delete.subset_id)
  end
end

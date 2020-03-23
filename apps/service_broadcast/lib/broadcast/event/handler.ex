defmodule Broadcast.Event.Handler do
  use Brook.Event.Handler
  use Properties, otp_app: :service_broadcast
  require Logger

  import Events,
    only: [
      load_broadcast_start: 0,
      load_broadcast_end: 0,
      transform_define: 0,
      dataset_delete: 0
    ]

  getter(:endpoints, required: true)

  def handle_event(%Brook.Event{type: load_broadcast_start(), data: %Load.Broadcast{} = load}) do
    Logger.debug(fn ->
      "#{__MODULE__}: Received event #{load_broadcast_start()}: #{inspect(load)}"
    end)

    Broadcast.Stream.Supervisor.start_child({Broadcast.Stream, load: load})
    Broadcast.Stream.Store.persist(load)
    :ok
  end

  def handle_event(%Brook.Event{type: load_broadcast_end(), data: %Load.Broadcast{} = load}) do
    terminate_stream(load)
  end

  def handle_event(%Brook.Event{type: transform_define(), data: %Transform{} = transform}) do
    Broadcast.Transformations.persist(transform)
  end

  def handle_event(%Brook.Event{type: dataset_delete(), data: %Delete{} = delete}) do
    Logger.debug(fn ->
      "#{__MODULE__}: Received event #{dataset_delete()}: #{inspect(delete)}"
    end)

    case Broadcast.Stream.Store.get!(delete.dataset_id, delete.subset_id) do
      nil ->
        Logger.debug("No existing state to delete")
        nil

      load ->
        terminate_stream(load)
        if Elsa.topic?(endpoints(), load.source), do: Elsa.delete_topic(endpoints(), load.source)
        Logger.debug("Deleted kafka topic")
    end

    Broadcast.Transformations.delete(delete)
    Broadcast.Stream.Store.delete(delete.dataset_id, delete.subset_id)
  end

  defp terminate_stream(%Load.Broadcast{} = load) do
    name = Broadcast.Stream.name(load)

    case Process.whereis(name) do
      nil ->
        Logger.debug("No Stream to delete")
        :ok

      pid ->
        Logger.debug("Deleting stream")
        Broadcast.Stream.Supervisor.terminate_child(pid)
        Broadcast.Stream.Store.mark_done(load)
        :ok
    end
  end
end

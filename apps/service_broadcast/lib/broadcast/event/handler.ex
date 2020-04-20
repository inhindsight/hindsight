defmodule Broadcast.Event.Handler do
  @moduledoc """
  Callbacks for handling events from `Brook`.
  """
  use Brook.Event.Handler
  use Properties, otp_app: :service_broadcast
  require Logger

  import Events,
    only: [
      load_start: 0,
      load_end: 0,
      transform_define: 0,
      dataset_delete: 0
    ]

  getter(:endpoints, required: true)

  def handle_event(%Brook.Event{
        type: load_start(),
        data: %Load{destination: %Channel.Topic{}} = load
      }) do
    Logger.debug(fn ->
      "#{__MODULE__}: Received event #{load_start()}: #{inspect(load)}"
    end)

    Broadcast.Stream.Supervisor.start_child(load)
    Broadcast.Stream.Store.persist(load)
    :ok
  end

  def handle_event(%Brook.Event{
        type: load_end(),
        data: %Load{destination: %Channel.Topic{}} = load
      }) do
    terminate_stream(load)
  end

  def handle_event(%Brook.Event{type: transform_define(), data: %Transform{} = transform}) do
    Broadcast.Transformations.persist(transform)
  end

  def handle_event(%Brook.Event{type: dataset_delete(), data: %Delete{} = delete}) do
    Logger.debug(fn ->
      "#{__MODULE__}: Received event #{dataset_delete()}: #{inspect(delete)}"
    end)

    Broadcast.Transformations.delete(delete)

    case Broadcast.Stream.Store.get!(delete.dataset_id, delete.subset_id) do
      nil ->
        Logger.debug("No existing state to delete")
        nil

      load ->
        terminate_stream(load)
        Broadcast.Stream.Store.delete(delete.dataset_id, delete.subset_id)
        Source.delete(load.source)
        Destination.delete(load.destination)
    end

    :ok
  end

  defp terminate_stream(%Load{} = load) do
    Broadcast.Stream.Supervisor.terminate_child(load)
    Broadcast.Stream.Store.mark_done(load)
  end
end

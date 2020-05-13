defmodule Broadcast.Event.Handler do
  @moduledoc """
  Callbacks for handling events from `Brook`.
  """
  use Brook.Event.Handler
  use Properties, otp_app: :service_broadcast
  require Logger
  import Definition, only: [identifier: 1]
  alias Broadcast.ViewState

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

    identifier(load)
    |> ViewState.Streams.persist(load)

    :ok
  end

  def handle_event(%Brook.Event{
        type: load_end(),
        data: %Load{destination: %Channel.Topic{}} = load
      }) do
    terminate_stream(load)
  end

  def handle_event(%Brook.Event{type: transform_define(), data: %Transform{} = transform}) do
    identifier(transform)
    |> ViewState.Transformations.persist(transform)
  end

  def handle_event(%Brook.Event{type: dataset_delete(), data: %Delete{} = delete}) do
    Logger.debug(fn ->
      "#{__MODULE__}: Received event #{dataset_delete()}: #{inspect(delete)}"
    end)

    key = identifier(delete)

    delete_transformation(key)

    case ViewState.Streams.get(key) do
      {:ok, nil} ->
        delete_source(key)
        delete_destination(key)
        :discard

      {:ok, stream} ->
        terminate_stream(stream)
        delete_source(key)
        delete_destination(key)

      {:error, reason} ->
        raise reason
    end
  end

  defp terminate_stream(%Load{} = load) do
    Broadcast.Stream.Supervisor.terminate_child(load)

    identifier(load)
    |> ViewState.Streams.delete()
  end

  defp delete_source(key) do
    case ViewState.Sources.get(key) do
      {:ok, nil} ->
        Logger.warn(fn -> "#{__MODULE__}: No source to delete for #{key}" end)
        :discard

      {:ok, source} ->
        Source.delete(source)
        ViewState.Sources.delete(key)

      {:error, reason} ->
        raise reason
    end
  end

  defp delete_destination(key) do
    case ViewState.Destinations.get(key) do
      {:ok, nil} ->
        Logger.warn(fn -> "#{__MODULE__}: No destination to delete for #{key}" end)
        :discard

      {:ok, destination} ->
        Destination.delete(destination)
        ViewState.Destinations.delete(key)

      {:error, reason} ->
        raise reason
    end
  end

  defp delete_transformation(key) do
    case ViewState.Transformations.get(key) do
      {:ok, nil} ->
        Logger.warn(fn -> "#{__MODULE__}: No transformations to delete for #{key}" end)
        :discard

      {:ok, _transformation} ->
        ViewState.Transformations.delete(key)

      {:error, reason} ->
        raise reason
    end
  end
end

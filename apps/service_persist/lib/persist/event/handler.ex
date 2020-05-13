defmodule Persist.Event.Handler do
  @moduledoc """
  Callbacks for handling events from `Brook`.
  """
  use Brook.Event.Handler
  use Properties, otp_app: :service_persist
  require Logger

  import Definition, only: [identifier: 1]

  import Events,
    only: [
      load_start: 0,
      load_end: 0,
      transform_define: 0,
      compact_start: 0,
      compact_end: 0,
      dataset_delete: 0
    ]

  alias Persist.ViewState

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

    key = identifier(load)
    ViewState.Loads.persist(key, load)
    ViewState.Sources.persist(key, load.source)
    ViewState.Destinations.persist(key, load.destination)
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
    Events.send_compact_start(@instance, __MODULE__, load)

    identifier(load)
    |> ViewState.Loads.delete()
  end

  @impl Brook.Event.Handler
  def handle_event(%Brook.Event{type: transform_define(), data: %Transform{} = transform}) do
    identifier(transform)
    |> ViewState.Transformations.persist(transform)
  end

  @impl Brook.Event.Handler
  def handle_event(%Brook.Event{
        type: compact_start(),
        data: %Load{destination: %Presto.Table{}} = load
      }) do
    Persist.Load.Supervisor.terminate_child(load)
    Persist.Compact.Supervisor.start_child(load)

    identifier(load)
    |> ViewState.Compactions.persist(load)
  end

  @impl Brook.Event.Handler
  def handle_event(%Brook.Event{
        type: compact_end(),
        data: %Load{destination: %Presto.Table{}} = load
      }) do
    key = identifier(load)
    ViewState.Compactions.delete(key)

    case ViewState.Loads.get(key) do
      {:ok, nil} -> :discard
      {:ok, _} -> Persist.Load.Supervisor.start_child(load)
      {:error, reason} -> raise reason
    end
  end

  @impl Brook.Event.Handler
  def handle_event(%Brook.Event{type: dataset_delete(), data: %Delete{} = delete}) do
    Logger.debug(fn ->
      "#{__MODULE__}: Received event #{dataset_delete()}: #{inspect(delete)}"
    end)

    key = identifier(delete)

    case ViewState.Loads.get(key) do
      {:ok, nil} ->
        delete_compaction(key)
        delete_source(key)
        delete_destination(key)
        ViewState.Transformations.delete(key)

      {:ok, load} ->
        delete_load(load)
        delete_compaction(key)
        delete_source(key)
        delete_destination(key)
        ViewState.Transformations.delete(key)

      {:error, reason} ->
        raise reason
    end
  end

  defp delete_compaction(key) do
    case ViewState.Compactions.get(key) do
      {:ok, nil} ->
        :discard

      {:ok, load} ->
        Persist.Compact.Supervisor.terminate_child(load)
        ViewState.Compactions.delete(key)

      {:error, reason} ->
        raise reason
    end
  end

  defp delete_load(load) do
    Persist.Load.Supervisor.terminate_child(load)

    identifier(load)
    |> ViewState.Loads.delete()
  end

  defp delete_source(key) do
    case ViewState.Sources.get(key) do
      {:ok, nil} ->
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
        :discard

      {:ok, destination} ->
        Destination.delete(destination)
        ViewState.Destinations.delete(key)

      {:error, reason} ->
        raise reason
    end
  end
end

defmodule Gather.Event.Handler do
  @moduledoc """
  Callbacks for handling events from `Brook`.
  """
  use Brook.Event.Handler
  use Properties, otp_app: :service_gather
  require Logger

  alias Gather.{Extraction, ViewState}
  import Events, only: [extract_start: 0, extract_end: 0, dataset_delete: 0]
  import Definition, only: [identifier: 1]

  getter(:endpoints, required: true)

  def handle_event(%Brook.Event{type: extract_start(), data: %Extract{} = extract}) do
    Logger.debug(fn -> "#{__MODULE__}: Received event #{extract_start()}: #{inspect(extract)}" end)

    key = identifier(extract)

    Extraction.Supervisor.start_child(extract)
    ViewState.Extractions.persist(key, extract)
    ViewState.Sources.persist(key, extract.source)
    ViewState.Destinations.persist(key, extract.destination)
  end

  def handle_event(%Brook.Event{type: extract_end(), data: %Extract{} = extract}) do
    identifier(extract)
    |> ViewState.Extractions.delete()
  end

  def handle_event(%Brook.Event{type: dataset_delete(), data: %Delete{} = delete}) do
    Logger.debug(fn ->
      "#{__MODULE__}: Received event #{dataset_delete()}: #{inspect(delete)}"
    end)

    key = identifier(delete)

    case ViewState.Extractions.get(key) do
      {:ok, nil} ->
        delete_source(key)
        delete_destination(key)
        :discard

      {:ok, extract} ->
        Extraction.Supervisor.terminate_child(extract)
        delete_source(key)
        delete_destination(key)
        ViewState.Extractions.delete(key)

      {:error, reason} ->
        raise reason
    end
  end

  defp delete_source(key) do
    case ViewState.Sources.get(key) do
      {:ok, nil} ->
        Logger.warn(fn -> "#{__MODULE__}: No source to delete for #{key}" end)

      {:ok, source} ->
        Source.delete(source)
        ViewState.Sources.delete(key)
        Logger.debug(fn -> "#{__MODULE__}: Deleted source for #{key}" end)

      {:error, reason} ->
        raise reason
    end
  end

  def delete_destination(key) do
    case ViewState.Destinations.get(key) do
      {:ok, nil} ->
        Logger.warn(fn -> "#{__MODULE__}: No destination to delete for #{key}" end)

      {:ok, destination} ->
        Destination.delete(destination)
        ViewState.Destinations.delete(key)
        Logger.debug(fn -> "#{__MODULE__}: Deleted destination for #{key}" end)

      {:error, reason} ->
        raise reason
    end
  end
end

defmodule Gather.Event.Handler do
  use Brook.Event.Handler
  use Properties, otp_app: :service_gather
  require Logger

  alias Gather.Extraction
  import Events, only: [extract_start: 0, extract_end: 0, definition_delete: 0]

  getter(:endpoints, required: true)

  def handle_event(%Brook.Event{type: extract_start(), data: %Extract{} = extract}) do
    Logger.debug(fn -> "#{__MODULE__}: Received event #{extract_start()}: #{inspect(extract)}" end)

    Extraction.Supervisor.start_child(extract)
    Extraction.Store.persist(extract)
  end

  def handle_event(%Brook.Event{type: extract_end(), data: %Extract{} = extract}) do
    Extraction.Store.mark_done(extract)
  end

  def handle_event(%Brook.Event{type: definition_delete(), data: %Delete{} = delete}) do
    Logger.debug(fn ->
      "#{__MODULE__}: Received event #{definition_delete()}: #{inspect(delete)}"
    end)

    case Extraction.Store.get!(delete.dataset_id, delete.subset_id) do
      nil ->
        nil

      extract ->
        if Elsa.topic?(endpoints(), extract.source),
          do: Elsa.delete_topic(endpoints(), extract.source)
    end

    Extraction.Store.delete(delete.dataset_id, delete.subset_id)
  end
end

defmodule Gather.Event.Handler do
  use Brook.Event.Handler
  require Logger

  alias Gather.Extraction
  import Events, only: [extract_start: 0, extract_end: 0]

  def handle_event(%Brook.Event{type: extract_start(), data: %Extract{} = extract}) do
    Logger.debug(fn -> "#{__MODULE__}: Received event #{extract_start()}: #{inspect(extract)}" end)

    Extraction.Supervisor.start_child(extract)
    Extraction.Store.persist(extract)
  end

  def handle_event(%Brook.Event{type: extract_end(), data: %Extract{} = extract}) do
    Extraction.Store.delete(extract.dataset_id, extract.subset_id)
  end
end

defmodule Gather.Event.Handler do
  use Brook.Event.Handler

  alias Gather.Extraction
  import Definition.Events, only: [extract_start: 0, extract_end: 0]

  def handle_event(%Brook.Event{type: extract_start(), data: %Extract{} = extract}) do
    Extraction.Supervisor.start_child({Extraction, extract: extract})
    Extraction.Store.persist(extract)
  end

  def handle_event(%Brook.Event{type: extract_end()}) do
    :ok
  end
end

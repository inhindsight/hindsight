defmodule Gather.Event.Handler do
  use Brook.Event.Handler

  alias Gather.Extraction

  def handle_event(%Brook.Event{type: "extract:start", data: %Extract{} = extract}) do
    Extraction.Supervisor.start_child({Extraction, extract: extract})
    Extraction.Store.persist(extract)
  end

  def handle_event(%Brook.Event{type: "extract:end"}) do
    :ok
  end
end

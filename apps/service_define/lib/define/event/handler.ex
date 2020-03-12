defmodule Define.Event.Handler do
  use Brook.Event.Handler
  require Logger

  import Events, only: [extract_start: 0, transform_define: 0, load_persist_start: 0]

  def handle_event(%Brook.Event{type: extract_start(), data: %Extract{} = extract}) do
    Define.Store.update_definition(extract)
  end

  def handle_event(%Brook.Event{type: transform_define(), data: %Transform{} = transform}) do
    Define.Store.update_definition(transform)
  end

  def handle_event(%Brook.Event{type: load_persist_start(), data: %Load.Persist{} = persist}) do
    Define.Store.update_definition(persist)
  end
end

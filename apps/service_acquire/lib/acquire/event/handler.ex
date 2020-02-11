defmodule Acquire.Event.Handler do
  use Brook.Event.Handler

  import Events, only: [transform_define: 0, load_persist_start: 0]

  def handle_event(%Brook.Event{type: transform_define(), data: %Transform{} = transform}) do
    Acquire.Dictionaries.persist(transform)
  end

  def handle_event(%Brook.Event{type: load_persist_start(), data: %Load.Persist{} = persist}) do
    Acquire.Dictionaries.persist(persist)
  end
end

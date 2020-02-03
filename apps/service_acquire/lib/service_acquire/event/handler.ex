defmodule Acquire.Event.Handler do
	use Brook.Event.Handler

  import Events, only: [transform_define: 0]

  def handle_event(%Brook.Event{type: transform_define(), data: %Transform{} = transform}) do
    Acquire.Fields.persist(transform)
  end
end

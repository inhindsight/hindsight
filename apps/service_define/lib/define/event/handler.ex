defmodule Define.Event.Handler do
  @moduledoc false
  use Brook.Event.Handler
  require Logger

  import Events, only: [extract_start: 0, transform_define: 0, load_start: 0]

  @events [extract_start(), transform_define(), load_start()]

  def handle_event(%Brook.Event{type: event, data: data}) when event in @events do
    Define.Event.Store.update_definition(data)
  end
end

defmodule Gather.Event.Handler do
  use Brook.Event.Handler

  def handle_event(%Brook.Event{type: "gather:extract:start"}) do
    nil
  end

  def handle_event(%Brook.Event{type: "gather:extract:stop"}) do
    nil
  end
end

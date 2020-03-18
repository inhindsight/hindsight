defmodule Profile.Event.Handler do
  use Brook.Event.Handler

  import Events, only: [extract_start: 0]

  def handle_event(%Brook.Event{type: extract_start(), data: extract}) do
    Profile.Feed.Supervisor.start_child(extract)

    :ok
  end
end

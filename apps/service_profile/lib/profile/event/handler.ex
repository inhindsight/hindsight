defmodule Profile.Event.Handler do
  use Brook.Event.Handler

  import Events, only: [extract_start: 0, profile_update: 0]

  def handle_event(%Brook.Event{type: extract_start(), data: %Extract{destination: %Kafka.Topic{}} = extract}) do
    Profile.Feed.Supervisor.start_child(extract)
    Profile.Feed.Store.persist(extract)
  end

  def handle_event(%Brook.Event{type: profile_update(), data: %Profile.Update{} = update}) do
    Profile.Feed.Store.persist(update)
  end
end

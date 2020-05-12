defmodule Profile.Event.Handler do
  @moduledoc """
  Callbacks for handling events from `Brook`.
  """
  use Brook.Event.Handler
  require Logger

  import Events, only: [extract_start: 0, profile_update: 0]
  import Definition, only: [identifier: 1]

  def handle_event(%Brook.Event{
        type: extract_start(),
        data: %Extract{destination: %Kafka.Topic{}} = extract
      }) do
    Logger.debug(fn ->
      "#{__MODULE__}: Received event #{extract_start()}: #{inspect(extract)}"
    end)

    Profile.Feed.Supervisor.start_child(extract)

    identifier(extract)
    |> Profile.ViewState.Extractions.persist(extract)
  end

  def handle_event(%Brook.Event{type: profile_update(), data: %Profile.Update{} = update}) do
    Logger.debug(fn ->
      "#{__MODULE__}: Received event #{profile_update()}: #{inspect(update)}"
    end)

    identifier(update)
    |> Profile.ViewState.Stats.persist(update.stats)
  end
end

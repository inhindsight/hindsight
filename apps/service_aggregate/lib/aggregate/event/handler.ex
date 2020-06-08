defmodule Aggregate.Event.Handler do
  @moduledoc """
  Callbacks for handling events from `Brook`.
  """
  use Brook.Event.Handler
  require Logger

  import Events, only: [extract_start: 0, aggregate_update: 0]
  import Definition, only: [identifier: 1]

  def handle_event(%Brook.Event{
        type: extract_start(),
        data: %Extract{destination: %Kafka.Topic{}} = extract
      }) do
    Logger.debug(fn ->
      "#{__MODULE__}: Received event #{extract_start()}: #{inspect(extract)}"
    end)

    Aggregate.Feed.Supervisor.start_child(extract)

    identifier(extract)
    |> Aggregate.ViewState.Extractions.persist(extract)
  end

  def handle_event(%Brook.Event{type: aggregate_update(), data: %Aggregate.Update{} = update}) do
    Logger.debug(fn ->
      "#{__MODULE__}: Received event #{aggregate_update()}: #{inspect(update)}"
    end)

    identifier(update)
    |> Aggregate.ViewState.Stats.persist(update.stats)
  end
end

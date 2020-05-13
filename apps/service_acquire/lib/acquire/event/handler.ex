defmodule Acquire.Event.Handler do
  @moduledoc """
  Callbacks for handling events from `Brook`.
  """
  use Brook.Event.Handler
  require Logger
  import Events, only: [transform_define: 0, load_start: 0, dataset_delete: 0]
  import Definition, only: [identifier: 1]
  alias Acquire.ViewState

  def handle_event(%Brook.Event{type: transform_define(), data: %Transform{} = transform}) do
    with {:ok, dictionary} <-
           Transformer.transform_dictionary(transform.steps, transform.dictionary) do
      identifier(transform)
      |> ViewState.Fields.persist(dictionary)
    end
  end

  def handle_event(%Brook.Event{
        type: load_start(),
        data: %Load{destination: %Presto.Table{}} = load
      }) do
    identifier(load)
    |> ViewState.Destinations.persist(load.destination)
  end

  def handle_event(%Brook.Event{type: dataset_delete(), data: %Delete{} = delete}) do
    Logger.debug(fn ->
      "#{__MODULE__}: Received event #{dataset_delete()}: #{inspect(delete)}"
    end)

    key = identifier(delete)
    ViewState.Destinations.delete(key)
    ViewState.Fields.delete(key)
  end
end

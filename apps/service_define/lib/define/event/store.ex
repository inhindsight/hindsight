defmodule Define.Store do
  require Logger
  alias Define.{DefinitionSerialization}

  @instance Define.Application.instance()
  @collection "definitions"

  def update_definition(%Extract{} = data) do
    get(data.dataset_id)
    |> Map.put(:dataset_id, data.dataset_id)
    |> Map.put(:subset_id, data.subset_id)
    |> put_in_better([:extract, :destination], data.destination)
    |> put_in_better([:extract, :steps], DefinitionSerialization.serialize(data.steps))
    |> Map.put(:dictionary, DefinitionSerialization.serialize(data.dictionary))
    |> persist()
  end

  def update_definition(%Transform{} = data) do
    get(data.dataset_id)
    |> Map.put(:dataset_id, data.dataset_id)
    |> Map.put(:subset_id, data.subset_id)
    |> Map.put(:dictionary, data.dictionary)
    |> Map.put(:transform_steps, data.steps)
    |> persist()
  end

  def update_definition(%Load.Persist{} = data) do
    get(data.dataset_id)
    |> Map.put(:dataset_id, data.dataset_id)
    |> Map.put(:subset_id, data.subset_id)
    |> Map.put(:persist_source, data.source)
    |> Map.put(:persist_destination, data.destination)
    |> persist()
  end

  def update_definition(data) do
    Logger.error("Got unexpected data definition update: #{inspect(data)}")
  end

  def put_in_better(map, [hd], value) do
    Map.put(map, hd, value)
  end

  # TODO Move to utilities
  def put_in_better(map, [hd | tail], value) do
    next_value = Map.get(map, hd)
    Map.put(map, hd, put_in_better(next_value, tail, value))
  end

  def get(dataset_id) do
    case Brook.get!(@instance, @collection, dataset_id) do
      nil -> %Define.DataDefinitionView{}
      map -> map
    end
  end

  def delete_all_definitions() do
    Brook.Test.clear_view_state(@instance, @collection)
  end

  defp persist(data) do
    Brook.ViewState.merge(@collection, data.dataset_id, data)
  end
end

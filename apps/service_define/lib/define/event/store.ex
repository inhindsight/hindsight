defmodule Define.Store do
  require Logger
  alias Define.{DefinitionSerialization, ExtractView, PersistView, TransformView}

  @instance Define.Application.instance()
  @collection "definitions"

  def update_definition(%Extract{} = data) do
    get(data.dataset_id)
    |> Map.put(:dataset_id, data.dataset_id)
    |> Map.put(:subset_id, data.subset_id)
    |> Map.put(:extract, to_extract_view(data))
    |> persist()
  end

  def update_definition(%Transform{} = data) do
    get(data.dataset_id)
    |> Map.put(:dataset_id, data.dataset_id)
    |> Map.put(:subset_id, data.subset_id)
    |> Map.put(:transform, to_transform_view(data))
    |> persist()
  end

  def update_definition(%Load.Persist{} = data) do
    get(data.dataset_id)
    |> Map.put(:dataset_id, data.dataset_id)
    |> Map.put(:subset_id, data.subset_id)
    |> Map.put(:persist, to_persist_view(data))
    |> persist()
  end

  def update_definition(data) do
    Logger.error("Got unexpected data definition update: #{inspect(data)}")
  end

  defp to_extract_view(event) do
    %ExtractView{
      destination: event.destination,
      dictionary: DefinitionSerialization.serialize(event.dictionary),
      steps: DefinitionSerialization.serialize(event.steps)
    }
  end

  defp to_transform_view(event) do
    %TransformView{
      dictionary: DefinitionSerialization.serialize(event.dictionary),
      steps: DefinitionSerialization.serialize(event.steps)
    }
  end

  defp to_persist_view(event) do
    %PersistView{
      source: event.source,
      destination: event.destination
    }
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

defmodule Define.Event.Store do
  require Logger
  alias Define.DefinitionSerialization
  alias Define.Model.{DataDefinitionView, ExtractView, LoadView, TransformView}
  import Definition, only: [identifier: 1]

  @instance Define.Application.instance()
  @collection "definitions"

  def update_definition(%Transform{} = data) do
    update_definition_field(data, :transform, &to_transform_view/1)
  end

  def update_definition(%Load{} = data) do
    update_definition_field(data, :load, &to_load_view/1)
  end

  def update_definition(%Extract{} = data) do
    update_definition_field(data, :extract, &to_extract_view/1)
  end

  def update_definition(data) do
    Logger.error("Got unexpected data definition update: #{inspect(data)}")
  end

  defp update_definition_field(data, key, to_view_converter) do
    get_or_create(data)
    |> Map.put(key, to_view_converter.(data))
    |> persist()
  rescue
    err ->
      Logger.error("Unable to process transform event: #{inspect(err)}")
      discard()
  end

  def get(id) do
    Brook.get!(@instance, @collection, id)
  end

  def get_all() do
    Brook.get_all_values!(@instance, @collection)
  end

  def delete_all_definitions() do
    Brook.Test.clear_view_state(@instance, @collection)
  end

  defp to_extract_view(event) do
    ExtractView.new!(%{
      destination: event.destination,
      dictionary: DefinitionSerialization.serialize(event.dictionary),
      steps: DefinitionSerialization.serialize(event.steps)
    })
  end

  defp to_transform_view(event) do
    TransformView.new!(%{
      dictionary: DefinitionSerialization.serialize(event.dictionary),
      steps: DefinitionSerialization.serialize(event.steps)
    })
  end

  defp to_load_view(event) do
    LoadView.new!(%{
      source: event.source,
      destination: event.destination
    })
  end

  defp get_or_create(data) do
    case get(identifier(data)) do
      nil -> DataDefinitionView.new!(dataset_id: data.dataset_id, subset_id: data.subset_id)
      map -> map
    end
  end

  defp persist(data) do
    Brook.ViewState.merge(@collection, identifier(data), data)
  end

  defp discard() do
    :discard
  end
end

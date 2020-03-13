defmodule Define.Store do
  require Logger

  @instance Define.Application.instance()
  @collection "definitions"

  def update_definition(%Extract{} = data) do
    get(data.dataset_id)
    |> Map.put(:dataset_id, data.dataset_id)
    |> Map.put(:subset_id, data.subset_id)
    |> Map.put(:extract_destination, data.destination)
    |> Map.put(:extract_steps, data.steps)
    |> Map.put(:dictionary, data.dictionary)
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

  def get(dataset_id) do
    case Brook.get!(@instance, @collection, dataset_id) do
      nil ->
        %{}
        |> Define.DataDefinition.create()
        |> Ecto.Changeset.apply_changes()

      map ->
        map
    end
  end

  def delete_all_definitions() do
    Brook.Test.clear_view_state(@instance, @collection)
  end

  defp persist(data) do
    Brook.ViewState.merge(@collection, data.dataset_id, data)
  end
end

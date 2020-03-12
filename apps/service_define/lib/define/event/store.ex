defmodule Define.Store do
  require Logger

  @instance Define.Application.instance()
  @collection "definitions"

  def update_definition(%Extract{} = data) do
    get(data.dataset_id)
    |> Map.put("dataset_id", data.dataset_id)
    |> Map.put("subset_id", data.subset_id)
    |> Map.put("destination", data.destination)
    |> Map.put("steps", data.steps)
    |> Map.put("dictionary", data.dictionary)
    |> verify_and_persist()
  end

  def update_definition(%Transform{} = data) do
    get(data.dataset_id)
    |> Map.put("dataset_id", data.dataset_id)
    |> Map.put("subset_id", data.subset_id)
    |> Map.put("dictionary", data.dictionary)
    |> Map.put("steps", data.steps)
    |> verify_and_persist()
  end

  def update_definition(%Load.Persist{} = data) do
    get(data.dataset_id)
    |> Map.put("dataset_id", data.dataset_id)
    |> Map.put("subset_id", data.subset_id)
    |> Map.put("source", data.source)
    |> Map.put("destination", data.destination)
    |> verify_and_persist()
  end

  def update_definition(data) do
    IO.inspect(data, label: "Got unexpected update")
  end

  def get(dataset_id) do
    case Brook.get!(@instance, @collection, dataset_id) do
      nil -> %{}
      map -> map
    end
  end

  defp verify_and_persist(data) do
    data
    |> Define.DataDefinition.create()
    |> Ecto.Changeset.apply_changes()
    |> persist()
  end

  defp persist(data) do
    Brook.ViewState.merge(@collection, data.dataset_id, data)
  end
end

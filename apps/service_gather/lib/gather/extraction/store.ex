defmodule Gather.Extraction.Store do
  @instance Gather.Application.instance()
  @collection "extractions"

  import Definition, only: [identifier: 1, identifier: 2]

  def collection() do
    @collection
  end

  def persist(extract) do
    Brook.ViewState.merge(@collection, identifier(extract), %{extract: extract})
  end

  def get!(dataset_id, subset_id) do
    case Brook.get!(@instance, @collection, identifier(dataset_id, subset_id)) do
      nil -> nil
      map -> Map.get(map, :extract)
    end
  end

  def delete(dataset_id, subset_id) do
    Brook.ViewState.delete(@collection, identifier(dataset_id, subset_id))
  end

  def get_all!() do
    Brook.get_all_values!(@instance, @collection)
    |> Enum.map(&Map.get(&1, :extract))
  end
end

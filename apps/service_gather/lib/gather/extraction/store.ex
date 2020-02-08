defmodule Gather.Extraction.Store do
  @instance Gather.Application.instance()
  @collection "extractions"

  import Definition, only: [identifier: 1, identifier: 2]

  def collection() do
    @collection
  end

  @spec persist(Extract.t()) :: :ok
  def persist(extract) do
    Brook.ViewState.merge(@collection, identifier(extract), %{extract: extract})
  end

  @spec get!(dataset_id :: String.t(), subset_id :: String.t()) :: Extract.t()
  def get!(dataset_id, subset_id) do
    case Brook.get!(@instance, @collection, identifier(dataset_id, subset_id)) do
      nil -> nil
      map -> Map.get(map, :extract)
    end
  end

  @spec delete(dataset_id :: String.t(), subset_id :: String.t()) :: :ok
  def delete(dataset_id, subset_id) do
    Brook.ViewState.delete(@collection, identifier(dataset_id, subset_id))
  end

  @spec get_all!() :: [Extract.t()]
  def get_all!() do
    Brook.get_all_values!(@instance, @collection)
    |> Enum.map(&Map.get(&1, :extract))
  end
end

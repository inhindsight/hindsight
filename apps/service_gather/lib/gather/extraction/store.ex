defmodule Gather.Extraction.Store do

  @instance Gather.Application.instance()
  @collection "extractions"

  def persist(extract) do
    Brook.ViewState.merge(@collection, extract.id, %{extract: extract})
  end

  def get!(extract_id) do
    case Brook.get!(@instance, @collection, extract_id) do
      nil -> nil
      map -> Map.get(map, :extract)
    end
  end

  def delete(extract_id) do
    Brook.ViewState.delete(@collection, extract_id)
  end

  def get_all!() do
    Brook.get_all!(@instance, @collection)
    |> Enum.map(&Map.get(&1, :extract))
  end
end

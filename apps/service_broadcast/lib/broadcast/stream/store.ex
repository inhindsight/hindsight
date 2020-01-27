defmodule Broadcast.Stream.Store do
  @instance Broadcast.Application.instance()
  @collection "streams"

  def persist(%Load.Broadcast{} = load) do
    Brook.ViewState.merge(@collection, load.id, %{"load" => load})
  end

  def get!(id) do
    case Brook.get!(@instance, @collection, id) do
      nil -> nil
      map -> Map.get(map, "load")
    end
  end

  def delete(id) do
    Brook.ViewState.delete(@collection, id)
  end

  def get_all!() do
    Brook.get_all_values!(@instance, @collection)
    |> Enum.map(&Map.get(&1, "load"))
  end
end

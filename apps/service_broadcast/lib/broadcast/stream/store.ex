defmodule Broadcast.Stream.Store do
  @moduledoc """
  State management functions for events.
  """

  @instance Broadcast.Application.instance()
  @collection "streams"

  import Definition, only: [identifier: 1, identifier: 2]

  @spec persist(Load.t()) :: :ok
  def persist(%Load{} = load) do
    Brook.ViewState.merge(@collection, identifier(load), %{"load" => load})
  end

  @spec mark_done(Load.t()) :: :ok
  def mark_done(%Load{} = load) do
    Brook.ViewState.merge(@collection, identifier(load), %{"done" => true})
  end

  @spec done?(Load.t()) :: boolean
  def done?(%Load{} = load) do
    case Brook.get!(@instance, @collection, identifier(load)) do
      nil -> false
      map -> Map.get(map, "done", false)
    end
  end

  @spec get!(dataset_id :: String.t(), subset_id :: String.t()) :: Load.t() | nil
  def get!(dataset_id, subset_id) do
    case Brook.get!(@instance, @collection, identifier(dataset_id, subset_id)) do
      nil -> nil
      map -> Map.get(map, "load")
    end
  end

  @spec delete(dataset_id :: String.t(), subset_id :: String.t()) :: :ok
  def delete(dataset_id, subset_id) do
    Brook.ViewState.delete(@collection, identifier(dataset_id, subset_id))
  end

  @spec get_all() :: [Load.t()]
  def get_all() do
    with {:ok, _state} = results <- Brook.get_all_values(@instance, @collection) do
      Ok.map(results, fn col -> Enum.map(col, &Map.get(&1, "load")) end)
    end
  end
end

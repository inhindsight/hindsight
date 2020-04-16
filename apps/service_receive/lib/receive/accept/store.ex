defmodule Receive.Accept.Store do
  @moduledoc """
  State management functions for events.
  """

  @instance Receive.Application.instance()
  @collection "accepts"

  import Definition, only: [identifier: 1, identifier: 2]

  @spec collection() :: String.t()
  def collection(), do: @collection

  @spec persist(Accept.t()) :: :ok
  def persist(accept) do
    Brook.ViewState.merge(@collection, identifier(accept), %{"accept" => accept})
  end

  @spec get!(dataset_id :: String.t(), subset_id :: String.t()) :: Accept.t() | nil
  def get!(dataset_id, subset_id) do
    case Brook.get!(@instance, @collection, identifier(dataset_id, subset_id)) do
      nil -> nil
      map -> Map.get(map, "accept")
    end
  end

  @spec mark_done(Accept.t()) :: :ok
  def mark_done(%Accept{} = accept) do
    Brook.ViewState.merge(@collection, identifier(accept), %{"done" => true})
  end

  @spec done?(Accept.t()) :: boolean
  def done?(%Accept{} = accept) do
    case Brook.get!(@instance, @collection, identifier(accept)) do
      nil -> false
      map -> Map.get(map, "done", false)
    end
  end

  @spec delete(dataset_id :: String.t(), subset_id :: String.t()) :: :ok
  def delete(dataset_id, subset_id) do
    Brook.ViewState.delete(@collection, identifier(dataset_id, subset_id))
  end

  @spec get_all() :: [Accept.t()]
  def get_all() do
    with {:ok, _state} = results <- Brook.get_all_values(@instance, @collection) do
      Ok.map(results, fn col -> Enum.map(col, &Map.get(&1, "accept")) end)
    end
  end
end

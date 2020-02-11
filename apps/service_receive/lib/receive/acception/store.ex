defmodule Receive.Acception.Store do
  @instance Receive.Application.instance()
  @collection "acceptions"

  import Definition, only: [identifier: 1, identifier: 2]

  @spec collection() :: String.t()
  def collection(), do: @collection

  @spec persist(Accept.t()) :: :ok
  def persist(accept) do
    Brook.ViewState.merge(@collection, identifier(accept), %{accept: accept})
  end

  @spec get!(dataset_id :: String.t(), subset_id :: String.t()) :: Accept.t()
  def get!(dataset_id, subset_id) do
    case Brook.get!(@instance, @collection, identifier(dataset_id, subset_id)) do
      nil -> nil
      map -> Map.get(map, :accept)
    end
  end

  @spec delete(dataset_id :: String.t(), subset_id :: String.t()) :: :ok
  def delete(dataset_id, subset_id) do
    Brook.ViewState.delete(@collection, identifier(dataset_id, subset_id))
  end

  @spec get_all!() :: [Accept.t()]
  def get_all!() do
    Brook.get_all_values!(@instance, @collection)
    |> Enum.map(&Map.get(&1, :accept))
  end
end

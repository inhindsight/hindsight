defmodule Persist.Load.Store do
  @instance Persist.Application.instance()
  @collection "loads"

  @spec persist(%Load.Persist{}) :: :ok
  def persist(%Load.Persist{} = load) do
    Brook.ViewState.merge(@collection, load.id, %{load: load})
  end

  @spec get!(id :: String.t()) :: %Load.Persist{}
  def get!(id) do
    case Brook.get!(@instance, @collection, id) do
      nil -> nil
      map -> Map.get(map, :load)
    end
  end

  @spec delete(id :: String.t()) :: :ok
  def delete(id) do
    Brook.ViewState.delete(@collection, id)
  end

  @spec get_all!() :: [%Load.Persist{}]
  def get_all!() do
    Brook.get_all_values!(@instance, @collection)
    |> Enum.map(&Map.get(&1, :load))
  end
end

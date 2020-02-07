defmodule Orchestrate.Schedule.Store do
  @collection "schedules"
  @instance Orchestrate.Application.instance()

  import Definition, only: [identifier: 2, identifier: 1]

  @spec persist(Schedule.t()) :: :ok
  def persist(%Schedule{} = schedule) do
    Brook.ViewState.merge(@collection, identifier(schedule), %{schedule: schedule})
  end

  @spec get(dataset_id :: String.t(), subset_id :: String.t()) :: {:ok, Schedule.t() | nil} | {:error, term}
  def get(dataset_id, subset_id) do
    case Brook.get(@instance, @collection, identifier(dataset_id, subset_id)) do
      {:ok, %{} = map} -> {:ok, Map.get(map, :schedule)}
      result -> result
    end
  end

  @spec get!(datset_id :: String.t(), subset_id :: String.t()) :: Schedule.t()
  def get!(dataset_id, subset_id) do
    case Brook.get!(@instance, @collection, identifier(dataset_id, subset_id)) do
      nil -> nil
      map -> Map.get(map, :schedule)
    end
  end

  @spec delete(dataset_id :: String.t(), subset_id :: String.t()) :: :ok
  def delete(dataset_id, subset_id) do
    Brook.ViewState.delete(@collection, identifier(dataset_id, subset_id))
  end
end

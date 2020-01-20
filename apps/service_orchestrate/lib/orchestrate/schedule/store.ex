defmodule Orchestrate.Schedule.Store do
  @collection "schedules"
  @instance Orchestrate.Application.instance()

  @spec persist(Schedule.t()) :: :ok
  def persist(%Schedule{id: id} = schedule) do
    Brook.ViewState.merge(@collection, id, %{schedule: schedule})
  end

  @spec get(String.t()) :: {:ok, Schedule.t() | nil} | {:error, term}
  def get(id) do
    case Brook.get(@instance, @collection, id) do
      {:ok, %{} = map} -> {:ok, Map.get(map, :schedule)}
      result -> result
    end
  end

  @spec get!(String.t()) :: Schedule.t()
  def get!(id) do
    case Brook.get!(@instance, @collection, id) do
      nil -> nil
      map -> Map.get(map, :schedule)
    end
  end

  @spec delete(String.t()) :: :ok
  def delete(id) do
    Brook.ViewState.delete(@collection, id)
  end
end

defmodule Orchestrate.Schedule.Store do
  @collection "schedules"
  @instance Orchestrate.Application.instance()

  def persist(%Schedule{id: id} = schedule) do
    Brook.ViewState.merge(@collection, id, %{schedule: schedule})
  end

  def get(id) do
    case Brook.get(@instance, @collection, id) do
      {:ok, %{} = map} -> {:ok, Map.get(map, :schedule)}
      result -> result
    end
  end

  def get!(id) do
    case Brook.get!(@instance, @collection, id) do
      nil -> nil
      map -> Map.get(map, :schedule)
    end
  end

  def delete(id) do
    Brook.ViewState.delete(@collection, id)
  end
end

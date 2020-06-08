defmodule Aggregate.Feed.Flow.State do
  @moduledoc """
  Simple state management functions for profiling `Flow`s.
  """
  def start_link(opts) do
    reducers = Keyword.fetch!(opts, :reducers)

    Agent.start_link(fn ->
      reducers
      |> Enum.map(fn %struct{} = reducer -> {struct, reducer} end)
      |> Map.new()
    end)
  end

  def get(server) do
    Agent.get(server, fn reducers -> Map.values(reducers) end)
  end

  def merge(server, reducers) do
    Agent.get_and_update(server, fn map ->
      reducers
      |> Enum.reduce({[], map}, fn %struct{} = reducer, {changed, state} ->
        old_reducer = Map.get(state, struct)
        new_reducer = Aggregate.Reducer.merge(old_reducer, reducer)
        new_changed = new_changes(new_reducer, old_reducer, changed)

        {new_changed, Map.put(state, struct, new_reducer)}
      end)
    end)
  end

  defp new_changes(new, new, changed), do: changed
  defp new_changes(new, _old, changed), do: [new | changed]
end

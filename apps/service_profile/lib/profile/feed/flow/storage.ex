defmodule Profile.Feed.Flow.Storage do
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
        new_reducer = Profile.Reducer.merge(old_reducer, reducer)

        new_changed =
          case old_reducer == new_reducer do
            true -> changed
            false -> [new_reducer | changed]
          end

        {new_changed, Map.put(state, struct, new_reducer)}
      end)
    end)
  end
end

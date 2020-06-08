defmodule Aggregate.Reducer.LongestString do
  defstruct [:path, :longest]

  def new(opts) do
    %__MODULE__{
      path: Keyword.fetch!(opts, :path),
      longest: 0
    }
  end

  defimpl Aggregate.Reducer do
    def init(t, stats) do
      %{t | longest: Map.get(stats, "longest_string", 0)}
    end

    def reduce(t, event) do
      string = get_in(event, t.path)
      Map.update!(t, :longest, &max(&1, String.length(string)))
    end

    def merge(t1, t2) do
      %{t1 | longest: max(t1.longest, t2.longest)}
    end

    def to_event_fields(t) do
      [{"longest_string", t.longest}]
    end
  end
end

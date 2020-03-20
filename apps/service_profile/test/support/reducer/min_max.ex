defmodule Profile.Reducer.MinMax do
  defstruct [:path, :min, :max]

  def new(opts) do
    %__MODULE__{
      path: Keyword.fetch!(opts, :path),
      min: nil,
      max: nil
    }
  end

  defimpl Profile.Reducer do
    def init(t, stats) do
      %{t | min: Map.get(stats, "min"), max: Map.get(stats, "max")}
    end

    def reduce(t, event) do
      value = get_in(event, t.path)

      t
      |> Map.update!(:min, &safe_min(&1, value))
      |> Map.update!(:max, &safe_max(&1, value))
    end

    def merge(t1, t2) do
      %{t1 | min: safe_min(t1.min, t2.min), max: safe_max(t1.max, t2.max)}
    end

    def to_event_fields(t) do
      [
        {"min", t.min},
        {"max", t.max}
      ]
    end

    defp safe_min(nil, nil), do: nil
    defp safe_min(a, nil), do: a
    defp safe_min(nil, b), do: b
    defp safe_min(a, b), do: min(a, b)

    defp safe_max(nil, nil), do: nil
    defp safe_max(a, nil), do: a
    defp safe_max(nil, b), do: b
    defp safe_max(a, b), do: max(a, b)
  end
end

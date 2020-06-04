defmodule Aggregate.Reducer.TemporalRange do
  @moduledoc """
  `Aggregate.Reducer` impl for calculating temporal range for datasets including
  temporal fields (date or timestamp).
  """
  defstruct [:path, :first, :last]

  def new(opts) do
    %__MODULE__{
      path: Keyword.fetch!(opts, :path),
      first: nil,
      last: nil
    }
  end

  defimpl Aggregate.Reducer do
    def init(t, map) do
      %{
        t
        | first: get_in(map, ["temporal_range", "first"]) |> parse(),
          last: get_in(map, ["temporal_range", "last"]) |> parse()
      }
    end

    def reduce(t, event) do
      value = get_in(event, t.path) |> parse()

      %{
        t
        | first: safe_first(t.first, value),
          last: safe_last(t.last, value)
      }
    end

    def merge(t1, t2) do
      %{
        t1
        | first: safe_first(t1.first, t2.first),
          last: safe_last(t1.last, t2.last)
      }
    end

    def to_event_fields(t) do
      [{"temporal_range", %{"first" => to_iso(t.first), "last" => to_iso(t.last)}}]
    end

    defp parse(nil), do: nil
    defp parse(string), do: NaiveDateTime.from_iso8601!(string)

    defp safe_first(nil, nil), do: nil
    defp safe_first(a, nil), do: a
    defp safe_first(nil, b), do: b

    defp safe_first(a, b) do
      case NaiveDateTime.diff(a, b) do
        x when x > 0 -> b
        _ -> a
      end
    end

    defp safe_last(nil, nil), do: nil
    defp safe_last(a, nil), do: a
    defp safe_last(nil, b), do: b

    defp safe_last(a, b) do
      case NaiveDateTime.diff(a, b) do
        x when x >= 0 -> a
        _ -> b
      end
    end

    defp to_iso(nil), do: nil
    defp to_iso(date_time), do: NaiveDateTime.to_iso8601(date_time)
  end
end

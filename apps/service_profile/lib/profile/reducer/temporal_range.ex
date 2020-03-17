defmodule Profile.Reducer.TemporalRange do
  defstruct [:path, :first, :last]

  def new(opts) do
    %__MODULE__{
      path: Keyword.fetch!(opts, :path),
      first: nil,
      last: nil
    }
  end

  defimpl Profile.Reducer do
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
        | first: first(t.first, value),
          last: last(t.last, value)
      }
    end

    def merge(t1, t2) do
      %{
        t1
        | first: first(t1.first, t2.first),
          last: last(t1.last, t2.last)
      }
    end

    def to_event_fields(t) do
      {"temporal_range", %{"first" => to_iso(t.first), "last" => to_iso(t.last)}}
    end

    defp parse(nil), do: nil
    defp parse(string), do: NaiveDateTime.from_iso8601!(string)

    defp first(nil, nil), do: nil
    defp first(a, nil), do: a
    defp first(nil, b), do: b

    defp first(a, b) do
      case NaiveDateTime.diff(a, b) do
        x when x > 0 -> b
        _ -> a
      end
    end

    defp last(nil, nil), do: nil
    defp last(a, nil), do: a
    defp last(nil, b), do: b

    defp last(a, b) do
      case NaiveDateTime.diff(a, b) do
        x when x >= 0 -> a
        _ -> b
      end
    end

    defp to_iso(nil), do: nil
    defp to_iso(date_time), do: NaiveDateTime.to_iso8601(date_time)
  end
end

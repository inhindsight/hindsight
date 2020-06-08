defmodule Aggregate.Reducer.BoundingBox do
  @moduledoc """
  `Aggregate.Reducer` impl for calculating a geospatial bounding box for datasets
  including geospatial fields (limited to latitude/longitude for now).
  """
  defstruct [:latitude_path, :longitude_path, :xmin, :ymin, :xmax, :ymax]

  def new(opts) do
    %__MODULE__{
      latitude_path: Keyword.fetch!(opts, :latitude_path),
      longitude_path: Keyword.fetch!(opts, :longitude_path),
      xmin: nil,
      ymin: nil,
      xmax: nil,
      ymax: nil
    }
  end

  defimpl Aggregate.Reducer do
    def init(t, stats) do
      case get_in(stats, ["bounding_box"]) do
        [xmin, ymin, xmax, ymax] ->
          %{
            t
            | xmin: xmin,
              ymin: ymin,
              xmax: xmax,
              ymax: ymax
          }

        _ ->
          t
      end
    end

    def reduce(t, event) do
      long = get_in(event, t.longitude_path)
      lat = get_in(event, t.latitude_path)

      %{
        t
        | xmin: safe_min(t.xmin, long),
          ymin: safe_min(t.ymin, lat),
          xmax: safe_max(t.xmax, long),
          ymax: safe_max(t.ymax, lat)
      }
    end

    def merge(t1, t2) do
      %{
        t1
        | xmin: safe_min(t1.xmin, t2.xmin),
          ymin: safe_min(t1.ymin, t2.ymin),
          xmax: safe_max(t1.xmax, t2.xmax),
          ymax: safe_max(t1.ymax, t2.ymax)
      }
    end

    def to_event_fields(t) do
      [{"bounding_box", [t.xmin, t.ymin, t.xmax, t.ymax]}]
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

defmodule Acquire.Query.Where.Bbox do
  alias Acquire.Query.ST

  def to_queryable([], _), do: Ok.ok(nil)

  def to_queryable([x1, y1, x2, y2], id) do
    with {:ok, envelope} <- bbox_envelope(x1, y1, x2, y2),
         {:ok, wkt_fields} <- Acquire.Dictionaries.get(id, "wkt"),
         {:ok, geometries} <- Ok.transform(wkt_fields, &ST.GeometryFromText.new(text: &1)) do
      case geometries do
        [geo] ->
          ST.intersects(envelope, geo)

        [_ | _] = geos ->
          Ok.transform(geos, &ST.intersects(envelope, &1))
          |> Ok.map(&Acquire.Query.Where.Or.new(conditions: &1))
      end
    end
  end

  defp bbox_envelope(x1, y1, x2, y2) do
    with {:ok, point2} <- ST.point(x2, y2) do
      ST.point(x1, y1)
      |> Ok.map(fn point1 -> ST.LineString.new(points: [point1, point2]) end)
      |> Ok.map(&ST.Envelope.new(geometry: &1))
    end
  end
end

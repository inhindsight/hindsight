defmodule Acquire.Query.Filter do
  # TODO
  @moduledoc false

  @spec from_params(params :: map) :: {Acquire.Query.statement(), list}
  def from_params(params) do
    filter = parse_filters(params)
    boundary = parse_boundary(params)

    where(filter, boundary)
  end

  defp where({[], _}, {nil, _}), do: {"", []}

  defp where({filters, filter_values}, {boundary, boundary_values}) do
    filter =
      Enum.filter([boundary | filters], & &1)
      |> Enum.join(" AND ")

    values =
      [boundary_values | Enum.reverse(filter_values)]
      |> List.flatten()

    {"WHERE #{filter}", values}
  end

  defp parse_filters(%{"filter" => filters}) do
    String.split(filters, ",", trim: true)
    |> Enum.map(&String.split(&1, "=", trim: true))
    |> Enum.map_reduce([], fn [k, v], acc -> {"#{k}=?", [v | acc]} end)
  end

  defp parse_filters(_), do: {[], []}

  defp parse_boundary(%{"boundary" => boundary}) do
    bbox =
      String.split(boundary, ",", trim: true)
      |> Enum.map(&String.trim/1)

    input = "ST_LineString(array[ST_Point(?, ?), ST_Point(?, ?)])"
    area = "ST_Envelope(#{input})"
    # TODO dynamic WKT field
    wkt = "ST_GeometryFromText(__wkt__)"

    {"ST_Contains(#{area}, #{wkt})", bbox}
  end

  defp parse_boundary(_), do: {nil, []}
end

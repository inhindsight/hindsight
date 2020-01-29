defmodule Acquire.Query do
  @moduledoc "TODO"

  @type statement :: String.t()

  @spec from_params(params :: map) :: {statement, list}
  def from_params(%{"dataset" => dataset} = params) do
    subset = Map.get(params, "subset", "default")
    fields = Map.get(params, "fields", "*")
    {where, values} = parse_where(params)

    statement =
      ["SELECT", fields, "FROM #{dataset}__#{subset}", where, limit(params)]
      |> Enum.filter(& &1)
      |> Enum.join(" ")
      |> String.trim()

    {statement, values}
  end

  defp parse_where(params) do
    {filter, filter_values} = filter(params)
    {boundary, boundary_values} = boundary(params)

    {where_clause(filter, boundary), filter_values ++ boundary_values}
  end

  defp where_clause([], []), do: ""

  defp where_clause(filter, boundary) do
    clause =
      filter ++ boundary
      |> Enum.join(" AND ")

    "WHERE #{clause}"
  end

  defp boundary(%{"boundary" => boundary}) do
    bbox =
      String.split(boundary, ",", trim: true)
      |> Enum.map(&String.to_float/1)

    input = "ST_LineString(array[ST_Point(?, ?), ST_Point(?, ?)])"
    envelope = "ST_Envelope(#{input})"
    # TODO get WKT field dynamically
    wkt = "ST_GeometryFromText(__wkt__)"

    {["ST_Contains(#{envelope}, #{wkt})"], bbox}
  end

  defp boundary(_), do: {[], []}

  defp filter(%{"filter" => filters}) do
    {keys, vals} =
      String.split(filters, ",", trim: true)
      |> Enum.map(fn filter -> String.split(filter, "=", trim: true) end)
      |> Enum.map_reduce([], fn [key, val], acc -> {"#{key}=?", [val | acc]} end)

    {keys, Enum.reverse(vals)}
  end

  defp filter(_), do: {[], []}

  defp limit(%{"limit" => limit}), do: "LIMIT #{limit}"
  defp limit(_), do: nil
end

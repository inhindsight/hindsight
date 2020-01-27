defmodule Acquire.Query do
  @moduledoc "TODO"

  @type statement :: String.t()

  @spec from_params(params :: map) :: {statement, list}
  def from_params(%{"dataset" => dataset} = params) do
    subset = Map.get(params, "subset", "default")
    fields = Map.get(params, "fields", "*")
    {filter, values} = filter(params)

    statement =
      ["SELECT", fields, "FROM #{dataset}__#{subset}", filter, limit(params)]
      |> Enum.filter(& &1)
      |> Enum.join(" ")
      |> String.trim()

    {statement, values}
  end

  defp filter(%{"filter" => filters}) do
    {keys, vals} =
      String.split(filters, ",", trim: true)
      |> Enum.map(fn filter -> String.split(filter, "=", trim: true) end)
      |> Enum.map_reduce([], fn [key, val], acc -> {"#{key}=?", [val | acc]} end)

    {"WHERE " <> Enum.join(keys, " AND "), Enum.reverse(vals)}
  end

  defp filter(_), do: {nil, []}

  defp limit(%{"limit" => limit}), do: "LIMIT #{limit}"
  defp limit(_), do: nil
end

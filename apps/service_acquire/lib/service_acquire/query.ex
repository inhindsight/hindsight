defmodule Acquire.Query do
  # TODO
  @moduledoc false

  @type statement :: String.t()

  @spec from_params(params :: map) :: {statement, list}
  def from_params(%{"dataset" => dataset} = params) do
    subset = Map.get(params, "subset", "default")
    fields = Map.get(params, "fields", "*")
    {where, values} = Acquire.Query.Filter.from_params(params)

    statement =
      ["SELECT", fields, "FROM #{dataset}__#{subset}", where, limit(params)]
      |> Enum.filter(& &1)
      |> Enum.join(" ")
      |> String.trim()

    {statement, values}
  end

  defp limit(%{"limit" => limit}), do: "LIMIT #{limit}"
  defp limit(_), do: nil
end

defmodule Acquire.Query.Where do
  alias Acquire.Query.Where.{And, FilterParser, Bbox}

  @spec from_params(params :: map) :: {:ok, Acquire.Queryable.t()} | {:error, term}
  def from_params(params) do
    with {:ok, operator} <- parse_operator(params),
         {:ok, boundary} <- parse_boundary(params) do
      make_queryable([operator, boundary])
    end
  end

  defp make_queryable(objects) do
    case Enum.filter(objects, & &1) do
      [] -> Ok.ok(nil)
      [condition] -> Ok.ok(condition)
      conditions -> And.new(conditions: conditions)
    end
  end

  defp parse_operator(params) do
    Map.get(params, "filter", "")
    |> String.split(",", trim: true)
    |> Ok.transform(&FilterParser.parse_operation/1)
    |> Ok.map(fn
      [] -> nil
      [fun] -> fun
      funs -> And.new(conditions: funs)
    end)
  end

  defp parse_boundary(%{"dataset" => dataset} = params) do
    subset = Map.get(params, "subset", "default")

    Map.get(params, "boundary", "")
    |> String.split(",", trim: true)
    |> Enum.map(&String.to_float/1)
    |> Bbox.to_queryable("#{dataset}__#{subset}")
  end
end

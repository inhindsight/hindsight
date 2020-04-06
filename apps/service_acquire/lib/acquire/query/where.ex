defmodule Acquire.Query.Where do
  @moduledoc false
  alias Acquire.Query.Where.{And, FilterParser, Bbox, Temporal}

  @spec from_params(params :: map) :: {:ok, Acquire.Queryable.t()} | {:error, term}
  def from_params(params) do
    with {:ok, operator} <- parse_operator(params),
         {:ok, temporal_clauses} <- parse_temporal(params),
         {:ok, boundary} <- parse_boundary(params) do
      [operator, temporal_clauses, boundary]
      |> make_queryable()
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
    |> Bbox.to_queryable(dataset, subset)
  end

  defp parse_temporal(%{"dataset" => dataset} = params) do
    subset = Map.get(params, "subset", "default")
    after_timestamp = Map.get(params, "after", "")
    before_timestamp = Map.get(params, "before", "")

    Temporal.to_queryable(dataset, subset, after_timestamp, before_timestamp)
    |> Ok.ok()
  end
end

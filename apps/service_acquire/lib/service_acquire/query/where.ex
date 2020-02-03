defmodule Acquire.Query.Where do
  use Definition, schema: Acquire.Query.Where.V1

  alias Acquire.Query.Where.{Function, And, FilterParser}
  alias Acquire.Query.Where.Bbox

  @type t :: %__MODULE__{
          operator: Queryable.t() | nil,
          boundary: Queryable.t() | nil
        }

  defstruct [:operator, :boundary]

  @spec from_params(params :: map) :: t
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

defmodule Acquire.Query.Where.V1 do
  use Definition.Schema

  alias Acquire.Query.Where.{Function, And, Or}

  @impl true
  def s do
    schema(%Acquire.Query.Where{
      operator: one_of([Function.schema(), And.schema(), spec(is_nil())]),
      boundary: one_of([Function.schema(), Or.schema(), spec(is_nil())])
    })
  end
end

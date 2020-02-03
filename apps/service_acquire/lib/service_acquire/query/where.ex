defmodule Acquire.Query.Where do
  use Definition, schema: Acquire.Query.Where.V1

  alias Acquire.Query.{Function}

  @type t :: %__MODULE__{
          operator: Queryable.t() | nil,
          boundary: Queryable.t() | nil
        }

  defstruct [:operator, :boundary]

  @spec from_params(params :: map) :: t
  def from_params(params) do
    Map.get(params, "filter", "")
    |> String.split(",", trim: true)
    |> Enum.map(&Acquire.Query.FilterParser.parse_operation/1)
    |> case do
         [] -> nil
         [fun] -> fun
         funs -> Acquire.Query.And.new!(conditions: funs)
       end
  end
end

defmodule Acquire.Query.Where.V1 do
  use Definition.Schema

  alias Acquire.Query.{Function, And, Or}

  @impl true
  def s do
    schema(%Acquire.Query.Where{
      operator: one_of([Function.schema(), And.schema(), spec(is_nil())]),
      boundary: one_of([Function.schema(), Or.schema(), spec(is_nil())])
    })
  end
end

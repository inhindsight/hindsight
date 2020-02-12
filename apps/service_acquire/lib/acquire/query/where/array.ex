defmodule Acquire.Query.Where.Array do
  use Definition, schema: Acquire.Query.Where.Array.V1

  @type t :: %__MODULE__{
          elements: [Acquire.Queryable.t()]
        }

  defstruct [:elements]

  defimpl Acquire.Queryable, for: __MODULE__ do
    def parse_statement(%{elements: elements}) do
      values =
        elements
        |> Enum.map(&Acquire.Queryable.parse_statement/1)
        |> Enum.join(", ")

      "array[#{values}]"
    end

    def parse_input(%{elements: elements}) do
      elements
      |> Enum.map(&Acquire.Queryable.parse_input/1)
      |> List.flatten()
    end
  end
end

defmodule Acquire.Query.Where.Array.V1 do
  use Definition.Schema

  def s do
    schema(%Acquire.Query.Where.Array{
      elements: spec(is_list())
    })
  end
end

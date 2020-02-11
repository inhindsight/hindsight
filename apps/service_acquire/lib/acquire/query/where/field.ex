defmodule Acquire.Query.Where.Field do
  use Definition, schema: Acquire.Query.Where.Field.V1

  @type t :: %__MODULE__{
          name: String.t()
        }

  defstruct [:name]

  defimpl Acquire.Queryable, for: __MODULE__ do
    def parse_statement(%{name: name}) do
      name
    end

    def parse_input(_) do
      []
    end
  end
end

defmodule Acquire.Query.Where.Field.V1 do
  use Definition.Schema

  def s do
    schema(%Acquire.Query.Where.Field{
      name: required_string()
    })
  end
end

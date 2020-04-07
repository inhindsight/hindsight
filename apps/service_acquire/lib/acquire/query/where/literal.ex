defmodule Acquire.Query.Where.Literal do
  @moduledoc false
  use Definition, schema: Acquire.Query.Where.Literal.V1

  @type t :: %__MODULE__{
          value: String.Chars.t()
        }

  defstruct [:value]

  defimpl Acquire.Queryable, for: __MODULE__ do
    def parse_statement(%{value: value}) when is_binary(value) do
      "'#{value}'"
    end

    def parse_statement(%{value: value}) do
      "#{value}"
    end

    def parse_input(_) do
      []
    end
  end
end

defmodule Acquire.Query.Where.Literal.V1 do
  @moduledoc false
  use Definition.Schema

  def s do
    schema(%Acquire.Query.Where.Literal{})
  end
end

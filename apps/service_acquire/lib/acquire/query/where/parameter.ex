defmodule Acquire.Query.Where.Parameter do
  use Definition, schema: Acquire.Query.Where.Parameter.Schema

  @type t :: %__MODULE__{value: term}

  defstruct [:value]

  defimpl Acquire.Queryable, for: __MODULE__ do
    def parse_statement(_) do
      "?"
    end

    def parse_input(%{value: value}) do
      [value]
    end
  end
end

defmodule Acquire.Query.Where.Parameter.Schema do
  use Definition.Schema

  @impl true
  def s do
    schema(%Acquire.Query.Where.Parameter{
      value: spec(not_nil?())
    })
  end
end

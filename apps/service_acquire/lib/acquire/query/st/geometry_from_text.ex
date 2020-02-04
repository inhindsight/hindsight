defmodule Acquire.Query.ST.GeometryFromText do
  use Definition, schema: Acquire.Query.ST.GeometryFromText.Schema

  @type t :: %__MODULE__{text: String.t()}

  defstruct [:text]

  defimpl Acquire.Queryable, for: __MODULE__ do
    def parse_statement(%{text: text}) do
      "ST_GeometryFromText(#{text})"
    end

    def parse_input(_), do: []
  end
end

defmodule Acquire.Query.ST.GeometryFromText.Schema do
  use Definition.Schema

  @impl true
  def s do
    schema(%Acquire.Query.ST.GeometryFromText{
      text: required_string()
    })
  end
end

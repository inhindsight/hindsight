defmodule Acquire.Query.ST.Envelope do
  use Definition, schema: Acquire.Query.ST.Envelope.Schema

  @type t :: %__MODULE__{geometry: Acquire.Queryable.t()}

  defstruct [:geometry]

  defimpl Acquire.Queryable, for: __MODULE__ do
    def parse_statement(envelope) do
      arg = Acquire.Queryable.parse_statement(envelope.geometry)
      "ST_Envelope(#{arg})"
    end

    def parse_input(envelope) do
      Acquire.Queryable.parse_input(envelope.geometry)
    end
  end
end

defmodule Acquire.Query.ST.Envelope.Schema do
  use Definition.Schema

  alias Acquire.Query.Where.Function
  alias Acquire.Query.ST.LineString

  @impl true
  def s do
    schema(%Acquire.Query.ST.Envelope{
      geometry: one_of([Function.schema(), LineString.schema()])
    })
  end
end

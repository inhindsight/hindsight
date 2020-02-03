defmodule Acquire.Query.ST.LineString do
  use Definition, schema: Acquire.Query.ST.LineString.V1

  @type t :: %__MODULE__{points: [Acquire.Query.ST.Point.t()]}

  defstruct points: []

  defimpl Acquire.Queryable, for: __MODULE__ do
    def parse_statement(ls) do
      points =
        Enum.map(ls.points, &Acquire.Queryable.parse_statement/1)
        |> Enum.join(", ")

      "ST_LineString(array[#{points}])"
    end

    def parse_input(ls) do
      Enum.flat_map(ls.points, &Acquire.Queryable.parse_input/1)
    end
  end
end

defmodule Acquire.Query.ST.LineString.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Acquire.Query.ST.LineString{
      points: coll_of(Acquire.Query.Function.schema())
    })
  end
end

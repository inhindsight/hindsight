defmodule Acquire.Query.And do
  use Definition, schema: Acquire.Query.And.V1
  defstruct [:conditions]

  defimpl Acquire.Queryable, for: __MODULE__ do
    alias Acquire.Queryable

    def parse_statement(query) do
      statement =
        Enum.map(query.conditions, &Queryable.parse_statement/1)
        |> Enum.join(" AND ")

      "(#{statement})"
    end

    def parse_input(query) do
      Enum.flat_map(query.conditions, &Queryable.parse_input/1)
    end
  end
end

defmodule Acquire.Query.And.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Acquire.Query.And{
      conditions: conditions()
    })
  end

  defp conditions do
    coll_of(spec(&condition?/1))
  end

  defp condition?(arg) do
    case Acquire.Queryable.impl_for(arg) do
      nil -> false
      _ -> true
    end
  end
end

defmodule Acquire.Query do
  # TODO
  @moduledoc false

  use Definition, schema: Acquire.Query.V1

  @type t :: %__MODULE__{
          table: String.t(),
          fields: [String.t()],
          limit: pos_integer() | nil,
          where: Acquire.Queryable.t()
        }

  defstruct table: nil,
            fields: ["*"],
            limit: nil,
            where: nil

  defimpl Acquire.Queryable, for: __MODULE__ do
    def parse_statement(query) do
      fields = Enum.join(query.fields, ", ")
      limit = limit_statement(query.limit)
      where = where_statement(query.where)

      ["SELECT", fields, "FROM", query.table, where, limit]
      |> Enum.filter(& &1)
      |> Enum.join(" ")
    end

    def parse_input(query) do
      where_input(query.where)
    end

    defp where_statement(nil), do: nil

    defp where_statement(query) do
      statement = Acquire.Queryable.parse_statement(query)
      "WHERE #{statement}"
    end

    defp where_input(nil), do: []
    defp where_input(query), do: Acquire.Queryable.parse_input(query)

    defp limit_statement(nil), do: nil
    defp limit_statement(n), do: "LIMIT #{n}"
  end
end

defmodule Acquire.Query.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Acquire.Query{
      table: spec(table_name?()),
      fields: coll_of(required_string()),
      limit: spec(is_nil() or pos_integer?())
    })
  end
end

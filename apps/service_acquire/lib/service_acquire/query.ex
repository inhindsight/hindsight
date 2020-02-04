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

    def parse_input(%Acquire.Query{where: nil}), do: []

    def parse_input(%Acquire.Query{} = query) do
      Acquire.Queryable.parse_input(query.where)
    end

    defp where_statement(nil), do: nil

    defp where_statement(where) do
      statement = Acquire.Queryable.parse_statement(where)
      "WHERE #{statement}"
    end

    defp limit_statement(nil), do: nil
    defp limit_statement(n), do: "LIMIT #{n}"
  end

  def from_params(%{"dataset" => dataset} = params) do
    subset = Map.get(params, "subset", "default")

    fields =
      Map.get(params, "fields", "*")
      |> String.split(",", trim: true)
      |> Enum.map(&String.trim/1)

    Acquire.Query.Where.from_params(params)
    |> Ok.map(
      &new(
        table: "#{dataset}__#{subset}",
        fields: fields,
        limit: limit(params),
        where: &1
      )
    )
  end

  defp limit(%{"limit" => limit}), do: String.to_integer(limit)
  defp limit(_), do: nil
end

defmodule Acquire.Query.V1 do
  use Definition.Schema

  alias Acquire.Query.Where.{Function, And, Or}

  @impl true
  def s do
    schema(%Acquire.Query{
      table: spec(table_name?()),
      fields: coll_of(required_string()),
      limit: spec(is_nil() or pos_integer?()),
      where: one_of([Function.schema(), And.schema(), Or.schema(), spec(is_nil())])
    })
  end
end

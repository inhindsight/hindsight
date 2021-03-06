defmodule Acquire.Query do
  @moduledoc false

  use Definition, schema: Acquire.Query.Schema
  import Definition, only: [identifier: 2]

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

  def from_params(params) do
    with {:ok, table_name} <- table(params),
         {:ok, where_clause} <- Acquire.Query.Where.from_params(params) do
      new(table: table_name, fields: fields(params), limit: limit(params), where: where_clause)
    end
  end

  defp table(%{"dataset" => dataset_id} = params) do
    subset_id = Map.get(params, "subset", "default")

    identifier(dataset_id, subset_id)
    |> Acquire.ViewState.Destinations.get()
    |> case do
      {:ok, nil} -> Ok.error("destination not found for #{dataset_id} #{subset_id}")
      {:ok, destination} -> Ok.ok(destination.name)
    end
  end

  defp fields(params) do
    Map.get(params, "fields", "*")
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
  end

  defp limit(%{"limit" => limit}), do: String.to_integer(limit)
  defp limit(_), do: nil
end

defmodule Acquire.Query.Schema do
  @moduledoc false
  use Definition.Schema

  alias Acquire.Query.Where.{Function, And, Or}

  @impl true
  def s do
    schema(%Acquire.Query{
      table: required_string(),
      fields: coll_of(required_string()),
      limit: spec(is_nil() or pos_integer?()),
      where: one_of([Function.schema(), And.schema(), Or.schema(), spec(is_nil())])
    })
  end
end

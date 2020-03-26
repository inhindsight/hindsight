defmodule Acquire.QueryTest do
  use ExUnit.Case
  import Checkov

  alias Acquire.Query
  alias Acquire.Queryable
  alias Acquire.Query.Where.{Function, And, Or, Parameter}
  import Acquire.Query.Where.Functions

  @instance Acquire.Application.instance()

  setup do
    Brook.Test.clear_view_state(@instance, "fields")
    :ok
  end

  describe "new/1" do
    data_test "validates #{key} against bad input" do
      input = put_in(%{table: "a__b"}, [key], value)
      assert {:error, [%{path: [^key | _]} | _]} = Query.new(input)

      where [
        [:key, :value],
        [:table, ""],
        [:table, nil],
        [:fields, nil],
        [:fields, [""]],
        [:limit, -1]
      ]
    end
  end

  describe "from_params/1" do
    setup do
      Brook.Test.with_event(@instance, fn ->
        Acquire.Dictionaries.persist(
          Load.Persist.new!(
            id: "persist-1",
            dataset_id: "a",
            subset_id: "default",
            source: Source.Fake.new(),
            destination: "table_name"
          )
        )
      end)

      :ok
    end

    test "returns default struct" do
      params = %{"dataset" => "a"}
      assert {:ok, %Query{} = query} = Query.from_params(params)

      assert query.table == "table_name"
      assert query.fields == ["*"]
      refute query.limit
      refute query.where
    end

    test "splits fields string into list of fields" do
      params = %{"dataset" => "a", "fields" => "x,y,z"}
      assert {:ok, %Query{fields: ["x", "y", "z"]}} = Query.from_params(params)
    end

    test "converts limit string into integer" do
      params = %{"dataset" => "a", "limit" => "42"}
      assert {:ok, %Query{limit: 42}} = Query.from_params(params)
    end

    test "return error tuple when unable to find destination" do
      params = %{"dataset" => "a", "subset" => "b"}
      assert {:error, "destination not found for a b"} == Query.from_params(params)
    end
  end

  describe "parsing" do
    test "parses statement from basic query" do
      query = Query.new!(table: "a__b")
      assert Queryable.parse_statement(query) == "SELECT * FROM a__b"
    end

    test "parses statement from query with fields" do
      query = Query.new!(table: "a__b", fields: ["one", "two"])
      assert Queryable.parse_statement(query) == "SELECT one, two FROM a__b"
    end

    test "parses statement from query with limit" do
      query = Query.new!(table: "a__b", limit: 42)
      assert Queryable.parse_statement(query) == "SELECT * FROM a__b LIMIT 42"
    end

    test "parses statement from query with single where clause" do
      fun = Function.new!(function: ">=", args: [field("one"), to_parameter(42)])
      query = Query.new!(table: "a__b", where: fun)

      assert Queryable.parse_statement(query) == "SELECT * FROM a__b WHERE one >= ?"
      assert Queryable.parse_input(query) == [42]
    end

    test "parses statement from query with two conditionals" do
      fun1 = Function.new!(function: "a", args: to_parameter([1, 2]))
      fun2 = Function.new!(function: "b", args: to_parameter([3, 4]))
      and1 = And.new!(conditions: [fun1, fun2])
      query = Query.new!(table: "a__b", where: and1)

      assert Queryable.parse_statement(query) == "SELECT * FROM a__b WHERE (a(?, ?) AND b(?, ?))"
      assert Queryable.parse_input(query) == [1, 2, 3, 4]
    end

    test "parses statement from complicated query" do
      fun1 = Function.new!(function: "a", args: to_parameter([1, 2]))
      fun2 = Function.new!(function: "b", args: to_parameter([3, 4]))
      and1 = And.new!(conditions: [fun1, fun2])
      fun3 = Function.new!(function: "=", args: [field("one"), to_parameter(5)])
      or1 = Or.new!(conditions: [and1, fun3])

      query = Query.new!(table: "a__b", fields: ["one", "two"], limit: 10, where: or1)

      assert Queryable.parse_statement(query) ==
               "SELECT one, two FROM a__b WHERE ((a(?, ?) AND b(?, ?)) OR one = ?) LIMIT 10"

      assert Queryable.parse_input(query) == [1, 2, 3, 4, 5]
    end
  end

  defp to_parameter(list) when is_list(list) do
    Enum.map(list, &to_parameter/1)
  end

  defp to_parameter(value), do: Parameter.new!(value: value)
end

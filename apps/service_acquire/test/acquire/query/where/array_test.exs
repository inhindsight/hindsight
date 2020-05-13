defmodule Acquire.Query.Where.ArrayTest do
  use ExUnit.Case

  alias Acquire.Query.Where.Array
  alias Acquire.Queryable
  import Acquire.Query.Where.Functions

  describe "Acquire.Queryable" do
    test "will return list of parameters" do
      array = Array.new!(elements: [parameter("one"), parameter("two")])

      assert "array[?, ?]" == Queryable.parse_statement(array)
      assert ["one", "two"] == Queryable.parse_input(array)
    end

    test "will include raw field" do
      array = Array.new!(elements: [field("field_a"), parameter("b")])

      assert "array[field_a, ?]" == Queryable.parse_statement(array)
      assert ["b"] == Queryable.parse_input(array)
    end

    test "will call queryable protocol for queryables" do
      array =
        Array.new!(
          elements: [
            date_parse(parameter("2020-01-01T01:01:01"), literal("<format>")),
            parameter("john"),
            field("field_b")
          ]
        )

      assert "array[date_parse(?, '<format>'), ?, field_b]" == Queryable.parse_statement(array)
      assert ["2020-01-01T01:01:01", "john"] == Queryable.parse_input(array)
    end
  end
end

defmodule Acquire.Query.AndTest do
  use ExUnit.Case
  import Checkov

  alias Acquire.Query.{And, Function, Parameter, Or}
  alias Acquire.Queryable

  describe "new/1" do
    data_test "validates against bad input" do
      input = put_in(%{}, [field], value)
      assert {:error, [%{path: [^field | _]} | _]} = And.new(input)

      where [
        [:field, :value],
        [:conditions, [true, false]],
        [:conditions, [Function.new!(function: "a", args: [1, 2]), true]]
      ]
    end
  end

  describe "parsing" do
    test "joins conditions into AND statement" do
      fun1 = Function.new!(function: "a", args: to_parameter([1, 2]))
      fun2 = Function.new!(function: "b", args: [fun1, to_parameter(3)])
      fun3 = Function.new!(function: "c", args: [to_parameter(4), fun2])
      fun4 = Function.new!(function: "d", args: [fun1, fun3])
      fun5 = Function.new!(function: "=", args: ["col", fun1])
      input = And.new!(conditions: [fun4, fun5, fun3])

      assert Queryable.parse_statement(input) ==
               "(d(a(?, ?), c(?, b(a(?, ?), ?))) AND col = a(?, ?) AND c(?, b(a(?, ?), ?)))"

      assert Queryable.parse_input(input) == [1, 2, 4, 1, 2, 3, 1, 2, 4, 1, 2, 3]
    end

    test "joins OR conditions into AND statement" do
      fun1 = Function.new!(function: "a", args: to_parameter([1, 2]))
      fun2 = Function.new!(function: ">", args: ["col1", "col2"])
      or1 = Or.new!(conditions: [fun1, fun2])

      fun3 = Function.new!(function: "b", args: to_parameter([3, 4]))
      fun4 = Function.new!(function: "c", args: ["col3", fun1])
      fun5 = Function.new!(function: "=", args: ["col4", to_parameter(5)])
      or2 = Or.new!(conditions: [fun3, fun4, fun5])

      input = And.new!(conditions: [fun1, or1, or2])

      assert Queryable.parse_statement(input) ==
               "(a(?, ?) AND (a(?, ?) OR col1 > col2) AND (b(?, ?) OR c(col3, a(?, ?)) OR col4 = ?))"

      assert Queryable.parse_input(input) == [1, 2, 1, 2, 3, 4, 1, 2, 5]
    end
  end

  defp to_parameter(list) when is_list(list) do
    Enum.map(list, &Parameter.new!(value: &1))
  end

  defp to_parameter(val) do
    Parameter.new!(value: val)
  end
end

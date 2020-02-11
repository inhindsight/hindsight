defmodule Acquire.Query.Where.FunctionTest do
  use ExUnit.Case
  import Checkov

  alias Acquire.Queryable
  alias Acquire.Query.Where.{Function, Parameter}

  describe "new/1" do
    data_test "validates for bad input" do
      input = put_in(%{function: "foo", args: [1, 2]}, [key], value)
      assert {:error, [%{path: [^key | _]} | _]} = Function.new(input)

      where [
        [:key, :value],
        [:function, nil],
        [:function, ""],
        [:args, nil]
      ]
    end
  end

  describe "parsing" do
    test "parameterizes raw input" do
      fun = Function.new!(function: "foo", args: to_parameter([1, 2]))
      assert Queryable.parse_statement(fun) == "foo(?, ?)"
      assert Queryable.parse_input(fun) == [1, 2]
    end

    test "nests function calls" do
      fun1 = Function.new!(function: "foo", args: to_parameter([1, 2]))
      fun2 = Function.new!(function: "bar", args: [fun1, to_parameter(3)])

      assert Queryable.parse_statement(fun2) == "bar(foo(?, ?), ?)"
      assert Queryable.parse_input(fun2) == [1, 2, 3]
    end

    test "nests a bunch of function calls" do
      fun1 = Function.new!(function: "a", args: to_parameter([1, 2]))
      fun2 = Function.new!(function: "b", args: [fun1, to_parameter(3), to_parameter(10)])
      fun3 = Function.new!(function: "c", args: [to_parameter(4), fun1])
      fun4 = Function.new!(function: "d", args: [fun2, fun3])

      assert Queryable.parse_statement(fun4) == "d(b(a(?, ?), ?, ?), c(?, a(?, ?)))"
      assert Queryable.parse_input(fun4) == [1, 2, 3, 10, 4, 1, 2]
    end

    test "parameterizes operators" do
      Enum.each(["=", ">", "<", ">=", "<=", "!="], fn op ->
        fun = Function.new!(function: op, args: ["col", to_parameter(42)])
        assert Queryable.parse_statement(fun) == "col #{op} ?"
        assert Queryable.parse_input(fun) == [42]
      end)
    end
  end

  defp to_parameter(values) when is_list(values) do
    Enum.map(values, fn v -> Parameter.new!(value: v) end)
  end

  defp to_parameter(value) do
    Parameter.new!(value: value)
  end
end

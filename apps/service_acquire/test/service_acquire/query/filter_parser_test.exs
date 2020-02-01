defmodule Acquire.Query.FilterParserTest do
  use ExUnit.Case
  import Checkov

  alias Acquire.Query.{FilterParser, Function, Parameter}

  describe "parse_operation/1" do
    data_test "parses filter into parameterized Function struct" do
      assert {:ok, ^fun} = FilterParser.parse_operation(input)

      where [
        [:input, :fun],
        ["foo=xyz", Function.new!(function: "=", args: ["foo", param("xyz")])],
        ["abc<42", Function.new!(function: "<", args: ["abc", param("42")])],
        ["abc>42", Function.new!(function: ">", args: ["abc", param("42")])],
        ["ABC>=42", Function.new!(function: ">=", args: ["ABC", param("42")])],
        ["ABC<=42", Function.new!(function: "<=", args: ["ABC", param("42")])],
        ["Z90!=A sentence.", Function.new!(function: "!=", args: ["Z90", param("A sentence.")])]
      ]
    end
  end

  defp param(value), do: Parameter.new!(value: value)
end

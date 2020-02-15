defmodule Acquire.Query.FilterParserTest do
  use ExUnit.Case
  import Checkov

  alias Acquire.Query.Where.{FilterParser, Function}

  import Acquire.Query.Where.Functions

  describe "parse_operation/1" do
    data_test "parses filter into parameterized Function struct" do
      assert {:ok, fun} == FilterParser.parse_operation(input)

      where [
        [:input, :fun],
        ["foo=xyz", Function.new!(function: "=", args: [field("foo"), parameter("xyz")])],
        ["abc<42", Function.new!(function: "<", args: [field("abc"), parameter("42")])],
        ["abc>42", Function.new!(function: ">", args: [field("abc"), parameter("42")])],
        ["ABC>=42", Function.new!(function: ">=", args: [field("ABC"), parameter("42")])],
        ["ABC<=42", Function.new!(function: "<=", args: [field("ABC"), parameter("42")])],
        [
          "Z90!=A sentence.",
          Function.new!(function: "!=", args: [field("Z90"), parameter("A sentence.")])
        ]
      ]
    end
  end
end

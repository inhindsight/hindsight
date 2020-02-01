defmodule Acquire.Query.FilterParserTest do
  use ExUnit.Case
  import Checkov

  alias Acquire.Query.FilterParser

  describe "operator/1" do
    data_test "parses operator and its arguments" do
      assert {^operator, ^args} = FilterParser.parse_operation(input)

      where [
        [:input, :operator, :args],
        ["foo=xyz", "=", ["foo", "xyz"]],
        ["FOO>42", ">", ["FOO", "42"]],
        ["abc<42", "<", ["abc", "42"]],
        ["ABC>=42", ">=", ["ABC", "42"]],
        ["a12<=42", "<=", ["a12", "42"]],
        ["Z90!=A sentence.", "!=", ["Z90", "A sentence."]],
      ]
    end
  end
end

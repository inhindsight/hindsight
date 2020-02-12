defmodule Acquire.Query.Where.LiteralTest do
  use ExUnit.Case

  alias Acquire.Query.Where.Literal

  describe "Acquire.Queryable" do
    test "handles binaries" do
      literal = Literal.new!(value: "one")

      assert "'one'" == Acquire.Queryable.parse_statement(literal)
      assert [] == Acquire.Queryable.parse_input(literal)
    end

    test "handles non binaries" do
      literal = Literal.new!(value: 1)

      assert "1" == Acquire.Queryable.parse_statement(literal)
      assert [] == Acquire.Queryable.parse_input(literal)
    end
  end
end

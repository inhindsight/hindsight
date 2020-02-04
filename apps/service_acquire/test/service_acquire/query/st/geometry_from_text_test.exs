defmodule Acquire.Query.ST.GeometryFromTextTest do
  use ExUnit.Case

  alias Acquire.Query.ST.GeometryFromText

  describe "parsing" do
    test "parses ST_GeometryFromText function" do
      gft = GeometryFromText.new!(text: "foo")
      assert Acquire.Queryable.parse_statement(gft) == "ST_GeometryFromText(foo)"
      assert Acquire.Queryable.parse_input(gft) == []
    end
  end
end

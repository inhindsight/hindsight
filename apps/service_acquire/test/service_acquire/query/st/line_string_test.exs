defmodule Acquire.Query.ST.LineStringTest do
  use ExUnit.Case

  alias Acquire.Query.ST
  alias Acquire.Query.Where.{Function, Parameter}
  alias Acquire.Queryable

  describe "new/1" do
    test "returns a LineString object" do
      points = [
        Function.new!(function: "foo", args: ["a", Parameter.new!(value: 42)]),
        Function.new!(function: "bar", args: ["b", Parameter.new!(value: 33)])
      ]

      assert {:ok, %ST.LineString{points: ^points}} = ST.LineString.new(points: points)
    end

    test "validates against bad input" do
      assert {:error, [%{path: [:points, 0]} | _]} = ST.LineString.new(points: [1.0, 2.0])
    end
  end

  describe "parsing" do
    test "parses a collection of points into a LineString" do
      expected = "ST_LineString(array[ST_Point(?, ?), ST_Point(?, ?), ST_Point(?, ?)])"
      points = [ST.point!(1.0, 2.0), ST.point!(3.0, 4.0), ST.point!(5.0, 6.0)]
      line_string = ST.LineString.new!(points: points)

      assert Queryable.parse_statement(line_string) == expected
      assert Queryable.parse_input(line_string) == [1.0, 2.0, 3.0, 4.0, 5.0, 6.0]
    end
  end
end

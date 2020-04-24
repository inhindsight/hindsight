defmodule Acquire.Query.STTest do
  use ExUnit.Case

  alias Acquire.Query.ST
  import Acquire.Query.Where.Functions

  describe "intersects/2" do
    test "returns ST_Intersects function object" do
      assert {:ok, fun} = ST.intersects(parameter("foo"), parameter("bar"))
      assert "ST_Intersects(?, ?)" == Acquire.Queryable.parse_statement(fun)
      assert ["foo", "bar"] == Acquire.Queryable.parse_input(fun)
    end
  end

  describe "point/2" do
    test "returns parameterized ST_Point function object" do
      {:ok, point} = ST.point(parameter(1.0), parameter(2.0))

      assert "ST_Point(?, ?)" == Acquire.Queryable.parse_statement(point)
      assert [1.0, 2.0] == Acquire.Queryable.parse_input(point)
    end
  end

  describe "envelope/1" do
    test "returns ST_Envelope call" do
      {:ok, envelope} = ST.envelope(parameter(1.0))

      assert "ST_Envelope(?)" == Acquire.Queryable.parse_statement(envelope)
      assert [1.0] == Acquire.Queryable.parse_input(envelope)
    end
  end

  describe "line_string/1" do
    test "can take array queryable" do
      {:ok, line_string} = ST.line_string(array([parameter(1.0), parameter(2.0)]))

      assert "ST_LineString(array[?, ?])" == Acquire.Queryable.parse_statement(line_string)
      assert [1.0, 2.0] == Acquire.Queryable.parse_input(line_string)
    end

    test "can take array of queryables" do
      {:ok, line_string} = ST.line_string([parameter(1.0), parameter(2.0), parameter(3.0)])

      assert "ST_LineString(array[?, ?, ?])" == Acquire.Queryable.parse_statement(line_string)
      assert [1.0, 2.0, 3.0] == Acquire.Queryable.parse_input(line_string)
    end
  end

  describe "geometry_from_text/1" do
    test "can take queryable" do
      {:ok, geo} = ST.geometry_from_text(parameter("one"))

      assert "ST_GeometryFromText(?)" == Acquire.Queryable.parse_statement(geo)
      assert ["one"] == Acquire.Queryable.parse_input(geo)
    end

    test "can take binary" do
      {:ok, geo} = ST.geometry_from_text("one")

      assert "ST_GeometryFromText(?)" == Acquire.Queryable.parse_statement(geo)
      assert ["one"] == Acquire.Queryable.parse_input(geo)
    end
  end
end

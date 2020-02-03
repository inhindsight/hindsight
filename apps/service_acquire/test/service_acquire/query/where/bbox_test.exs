defmodule Acquire.Query.Where.BboxTest do
  use ExUnit.Case
  use Placebo

  alias Acquire.Query.Where.Bbox
  alias Acquire.Query.{Function, Or, ST}

  describe "to_queryable/2" do
    test "returns queryable object for one geospatial field" do
      expect Acquire.Dictionaries.get("a__default", "wkt"), return: {:ok, ["foobar"]}

      points = [ST.Point.new!(1.0, 2.0), ST.Point.new!(3.0, 4.0)]
      ls = ST.LineString.new!(points: points)
      envelope = ST.Envelope.new!(geometry: ls)
      geometry = ST.GeometryFromText.new!(text: "foobar")

      assert {:ok, query} = Bbox.to_queryable([1.0, 2.0, 3.0, 4.0], "a__default")
      assert %Function{function: "ST_Intersects", args: [^envelope, ^geometry]} = query
    end

    test "returns queryable object for multiple geospatial fields" do
      expect Acquire.Dictionaries.get("a__default", "wkt"), return: {:ok, ["foo", "bar"]}

      points = [ST.Point.new!(1.0, 2.0), ST.Point.new!(3.0, 4.0)]
      ls = ST.LineString.new!(points: points)
      envelope = ST.Envelope.new!(geometry: ls)

      geo1 = ST.GeometryFromText.new!(text: "foo")
      fun1 = Function.new!(function: "ST_Intersects", args: [envelope, geo1])

      geo2 = ST.GeometryFromText.new!(text: "bar")
      fun2 = Function.new!(function: "ST_Intersects", args: [envelope, geo2])

      assert {:ok, query} = Bbox.to_queryable([1.0, 2.0, 3.0, 4.0], "a__default")
      assert %Or{conditions: [^fun1, ^fun2]} = query
    end
  end
end

defmodule Acquire.Query.Where.BboxTest do
  use ExUnit.Case
  use Placebo

  alias Acquire.Query.Where.Bbox
  alias Acquire.Query.ST
  alias Acquire.Query.Where.{Function, Or}

  @instance Acquire.Application.instance()

  describe "to_queryable/2" do
    test "returns queryable object for one geospatial field" do
      Brook.Test.with_event(@instance, fn ->
        Acquire.Dictionaries.persist(
          Transform.new!(
            id: "transform-1",
            dataset_id: "a",
            subset_id: "default",
            dictionary: [
              Dictionary.Type.Wkt.Point.new!(name: "foobar")
            ],
            steps: []
          )
        )
      end)

      points = [ST.point!(1.0, 2.0), ST.point!(3.0, 4.0)]
      ls = ST.LineString.new!(points: points)
      envelope = ST.Envelope.new!(geometry: ls)
      geometry = ST.GeometryFromText.new!(text: "foobar")

      assert {:ok, query} = Bbox.to_queryable([1.0, 2.0, 3.0, 4.0], "a", "default")
      assert %Function{function: "ST_Intersects", args: [^envelope, ^geometry]} = query
    end

    test "returns queryable object for multiple geospatial fields" do
      Brook.Test.with_event(@instance, fn ->
        Acquire.Dictionaries.persist(
          Transform.new!(
            id: "transform-1",
            dataset_id: "a",
            subset_id: "default",
            dictionary: [
              Dictionary.Type.Wkt.Point.new!(name: "bar"),
              Dictionary.Type.Wkt.Point.new!(name: "foo")
            ],
            steps: []
          )
        )
      end)

      points = [ST.point!(1.0, 2.0), ST.point!(3.0, 4.0)]
      ls = ST.LineString.new!(points: points)
      envelope = ST.Envelope.new!(geometry: ls)

      geo1 = ST.GeometryFromText.new!(text: "foo")
      fun1 = Function.new!(function: "ST_Intersects", args: [envelope, geo1])

      geo2 = ST.GeometryFromText.new!(text: "bar")
      fun2 = Function.new!(function: "ST_Intersects", args: [envelope, geo2])

      assert {:ok, query} = Bbox.to_queryable([1.0, 2.0, 3.0, 4.0], "a", "default")
      assert %Or{conditions: [^fun1, ^fun2]} = query
    end
  end
end

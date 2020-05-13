defmodule Acquire.Query.Where.BboxTest do
  use ExUnit.Case
  use Placebo
  import Definition, only: [identifier: 1]

  alias Acquire.Query.Where.Bbox
  alias Acquire.Query.ST
  alias Acquire.Query.Where.{Function, Or, Functions}

  @instance Acquire.Application.instance()

  setup do
    on_exit(fn ->
      Brook.Test.clear_view_state(@instance, Acquire.ViewState.Fields.collection())
    end)
  end

  describe "to_queryable/2" do
    test "returns queryable object for one geospatial field" do
      Brook.Test.with_event(@instance, fn ->
        transform =
          Transform.new!(
            id: "transform-1",
            dataset_id: "a",
            subset_id: "default",
            dictionary: [
              Dictionary.Type.Wkt.Point.new!(name: "foobar")
            ],
            steps: []
          )

        {:ok, dict} = Transformer.transform_dictionary(transform.steps, transform.dictionary)

        identifier(transform)
        |> Acquire.ViewState.Fields.persist(dict)
      end)

      points = [ST.point!(1.0, 2.0), ST.point!(3.0, 4.0)]
      {:ok, ls} = ST.line_string(points)
      {:ok, envelope} = ST.envelope(ls)
      {:ok, geometry} = ST.geometry_from_text(Functions.field("foobar"))

      assert {:ok, query} = Bbox.to_queryable([1.0, 2.0, 3.0, 4.0], "a", "default")
      assert %Function{function: "ST_Intersects", args: [envelope, geometry]} == query
    end

    test "returns queryable object for multiple geospatial fields" do
      Brook.Test.with_event(@instance, fn ->
        transform =
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

        {:ok, dict} = Transformer.transform_dictionary(transform.steps, transform.dictionary)

        identifier(transform)
        |> Acquire.ViewState.Fields.persist(dict)
      end)

      points = [ST.point!(1.0, 2.0), ST.point!(3.0, 4.0)]
      {:ok, ls} = ST.line_string(points)
      {:ok, envelope} = ST.envelope(ls)

      {:ok, geo1} = ST.geometry_from_text(Functions.field("foo"))
      fun1 = Function.new!(function: "ST_Intersects", args: [envelope, geo1])

      {:ok, geo2} = ST.geometry_from_text(Functions.field("bar"))
      fun2 = Function.new!(function: "ST_Intersects", args: [envelope, geo2])

      assert {:ok, query} = Bbox.to_queryable([1.0, 2.0, 3.0, 4.0], "a", "default")
      assert %Or{conditions: [fun1, fun2]} == query
    end
  end
end

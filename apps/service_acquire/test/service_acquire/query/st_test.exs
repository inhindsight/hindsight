defmodule Acquire.Query.STTest do
  use ExUnit.Case

  alias Acquire.Query.ST
  alias Acquire.Query.Where.{Function, Parameter}

  describe "intersects/2" do
    test "returns ST_Intersects function object" do
      assert {:ok, fun} = ST.intersects("foo", "bar")
      assert %Function{function: "ST_Intersects", args: ["foo", "bar"]} = fun
    end
  end

  describe "point/2" do
    test "returns parameterized ST_Point function object" do
      args = [Parameter.new!(value: 1.0), Parameter.new!(value: 2.0)]
      assert {:ok, %Function{function: "ST_Point", args: ^args}} = ST.point(1.0, 2.0)
    end
  end
end

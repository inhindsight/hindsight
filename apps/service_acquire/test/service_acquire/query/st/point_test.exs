defmodule Acquire.Query.ST.PointTest do
  use ExUnit.Case

  alias Acquire.Query.ST.Point
  alias Acquire.Query.Where.{Function, Parameter}

  describe "new/2" do
    test "returns parameterized ST_Point function" do
      args = [Parameter.new!(value: 1.0), Parameter.new!(value: 2.0)]
      assert {:ok, %Function{function: "ST_Point", args: ^args}} = Point.new(1.0, 2.0)
    end
  end
end

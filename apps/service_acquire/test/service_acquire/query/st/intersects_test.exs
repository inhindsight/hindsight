defmodule Acquire.Query.ST.IntersectsTest do
  use ExUnit.Case

  alias Acquire.Query.{ST, Function}

  describe "new/2" do
    test "returns ST_Intersects function" do
      assert {:ok, fun} = ST.Intersects.new("foo", "bar")
      assert %Function{function: "ST_Intersects", args: ["foo", "bar"]} = fun
    end
  end
end

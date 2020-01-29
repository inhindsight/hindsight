defmodule Acquire.Query.FilterTest do
  use Checkov

  alias Acquire.Query.Filter

  @geo "ST_Intersects(ST_Envelope(ST_LineString(array[ST_Point(?, ?), ST_Point(?, ?)])), ST_GeometryFromText(__wkt__))"

  describe "from_params/1" do
    data_test "parses parameterized WHERE clause from input" do
      assert Filter.from_params(input) == {clause, values}

      where [
        [:input, :clause, :values],
        [%{"filter" => "a=1"}, "WHERE a=?", ["1"]],
        [%{"filter" => "a=1,b=2"}, "WHERE a=? AND b=?", ["1", "2"]],
        [%{"boundary" => "1.0,1.1,2.2,2.3"}, "WHERE #{@geo}", [1.0, 1.1, 2.2, 2.3]],
        [
          %{"filter" => "a=1,b=foo", "boundary" => "1.0, 1.2, 3.4, 4.5"},
          "WHERE #{@geo} AND a=? AND b=?",
          [1.0, 1.2, 3.4, 4.5, "1", "foo"]
        ]
      ]
    end
  end
end

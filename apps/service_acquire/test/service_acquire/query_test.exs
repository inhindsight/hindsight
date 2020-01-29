defmodule Acquire.QueryTest do
  use Checkov

  describe "from_params/1" do
    data_test "constructs parameterized statement from given parameters" do
      input = Map.merge(%{"dataset" => "a", "subset" => "b"}, params)
      assert Acquire.Query.from_params(input) == statement

      where [
        [:params, :statement],
        [%{}, {"SELECT * FROM a__b", []}],
        [%{"fields" => "c,d"}, {"SELECT c,d FROM a__b", []}],
        [%{"filter" => "c=1"}, {"SELECT * FROM a__b WHERE c=?", ["1"]}],
        [%{"filter" => "c=1,d=2"}, {"SELECT * FROM a__b WHERE c=? AND d=?", ["1", "2"]}],
        [%{"limit" => "10"}, {"SELECT * FROM a__b  LIMIT 10", []}],
        [
          %{"boundary" => "1.0,1.0,2.0,2.0"},
          {"SELECT * FROM a__b WHERE ST_Contains(ST_Envelope(ST_LineString(array[ST_Point(?, ?), ST_Point(?, ?)])), ST_GeometryFromText(__wkt__))",
           ["1.0", "1.0", "2.0", "2.0"]}
        ]
      ]
    end
  end
end

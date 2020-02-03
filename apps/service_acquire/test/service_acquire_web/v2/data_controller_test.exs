defmodule AcquireWeb.V2.DataControllerTest do
  use AcquireWeb.ConnCase
  import Checkov
  use Placebo

  require Temp.Env

  Temp.Env.modify([
    %{
      app: :service_acquire,
      key: AcquireWeb.V2.DataController,
      set: [presto_client: Acquire.Db.Mock]
    }
  ])

  describe "select/2" do
    data_test "retrieves data", %{conn: conn} do
      allow Acquire.Fields.get("a__b", "wkt"), return: {:ok, ["__wkt__"]}

      data = [%{"a" => 42}]
      Mox.expect(Acquire.Db.Mock, :execute, fn ^query, ^values -> {:ok, data} end)

      actual = get(conn, path) |> json_response(200)
      assert actual == data

      where [
        [:path, :query, :values],
        ["/api/v2/data/a/b", "SELECT * FROM a__b", []],
        ["/api/v2/data/a", "SELECT * FROM a__default", []],
        ["/api/v2/data/a?limit=1", "SELECT * FROM a__default LIMIT 1", []],
        ["/api/v2/data/a/b?filter=a!=1", "SELECT * FROM a__b WHERE a != ?", ["1"]],
        [
          "/api/v2/data/a/b?fields=c&filter=c=42,d=9000",
          "SELECT c FROM a__b WHERE (c = ? AND d = ?)",
          ["42", "9000"]
        ],
        [
          "/api/v2/data/a/b?boundary=1.0,2.0,3.0,4.0",
          "SELECT * FROM a__b WHERE ST_Intersects(ST_Envelope(ST_LineString(array[ST_Point(?, ?), ST_Point(?, ?)])), ST_GeometryFromText(__wkt__))",
          [1.0, 2.0, 3.0, 4.0]
        ],
        [
          "/api/v2/data/a/b?filter=c>=42&boundary=1.0,2.0,3.0,4.0",
          "SELECT * FROM a__b WHERE (c >= ? AND ST_Intersects(ST_Envelope(ST_LineString(array[ST_Point(?, ?), ST_Point(?, ?)])), ST_GeometryFromText(__wkt__)))",
          ["42", 1.0, 2.0, 3.0, 4.0]
        ]
      ]
    end
  end
end

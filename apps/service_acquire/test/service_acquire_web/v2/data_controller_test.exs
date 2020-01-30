defmodule AcquireWeb.V2.DataControllerTest do
  use AcquireWeb.ConnCase
  import Checkov

  import Mox
  require Temp.Env

  Temp.Env.modify([
    %{
      app: :service_acquire,
      key: AcquireWeb.V2.DataController,
      set: [presto_client: Acquire.Db.Mock]
    }
  ])

  setup :verify_on_exit!

  describe "select/2" do
    data_test "retrieves data", %{conn: conn} do
      data = [%{"a" => 42}]
      expect(Acquire.Db.Mock, :execute, fn ^query, ^values -> {:ok, data} end)

      actual = get(conn, path) |> json_response(200)
      assert actual == data

      where [
        [:path, :query, :values],
        ["/api/v2/data/a/b", "SELECT * FROM a__b", []],
        ["/api/v2/data/a", "SELECT * FROM a__default", []],
        ["/api/v2/data/a?limit=1", "SELECT * FROM a__default  LIMIT 1", []],
        [
          "/api/v2/data/a/b?fields=c&filter=c=42,d=9000",
          "SELECT c FROM a__b WHERE c=? AND d=?",
          ["42", "9000"]
        ]
      ]
    end
  end
end

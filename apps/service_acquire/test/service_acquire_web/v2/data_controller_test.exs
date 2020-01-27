defmodule AcquireWeb.V2.DataControllerTest do
  use AcquireWeb.ConnCase
  import Checkov

  import Mox
  require Temp.Env

  Temp.Env.modify([
    %{
      app: :service_acquire,
      key: AcquireWeb.V2.DataController,
      set: [presto_client: Acquire.Presto.Mock]
    }
  ])

  setup :verify_on_exit!

  describe "select/2" do
    data_test "retrieves data", %{conn: conn} do
      data = [%{"a" => 42}]
      expect(Acquire.Presto.Mock, :execute, fn ^query, ^values -> {:ok, data} end)

      actual = get(conn, path) |> json_response(200)
      assert actual == data

      where [
        [:path, :query, :values],
        ["/api/v2/data/a/b", "SELECT * FROM a__b", []],
        ["/api/v2/data/a", "SELECT * FROM a__default", []]
      ]
    end
  end
end

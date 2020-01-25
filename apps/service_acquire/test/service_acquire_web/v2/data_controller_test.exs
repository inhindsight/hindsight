defmodule AcquireWeb.V2.DataControllerTest do
  use AcquireWeb.ConnCase

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
    test "retrieves all data by default", %{conn: conn} do
      data = [%{"a" => 1}]
      expect(Acquire.Presto.Mock, :execute, fn "select * from a__b" -> {:ok, data} end)

      actual = get(conn, "/api/v2/data/a/b") |> json_response(200)

      assert actual == data
    end

    test "queries default subset by default", %{conn: conn} do
      data = [%{"b" => 2}]
      expect(Acquire.Presto.Mock, :execute, fn "select * from a__default" -> {:ok, data} end)

      actual = get(conn, "/api/v2/data/a") |> json_response(200)

      assert actual == data
    end
  end
end

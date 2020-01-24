defmodule AcquireWeb.V2.DataControllerTest do
  use AcquireWeb.ConnCase

  import Mox

  setup :verify_on_exit!

  describe "select/2" do
    test "retrieves all data by default", %{conn: conn} do
      data = [%{"hi" => "test"}]
      expect(Acquire.Presto.Mock, :execute, fn "select * from a__b" -> {:ok, data} end)

      actual = get(conn, "/api/v2/data/a/b") |> json_response(200)

      assert actual == data
    end
  end
end

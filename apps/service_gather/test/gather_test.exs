defmodule GatherTest do
  use ExUnit.Case

  @instance Gather.Application.instance()

  setup do
    [bypass: Bypass.open()]
  end

  @tag :skip
  test "something, something, gather", %{bypass: bypass} do
    Bypass.expect(bypass, "GET", "/file.csv", fn conn ->
      Plug.Conn.resp(conn, 200, "one,two,three\nfour,five,six")
    end)

    extract =
      Extract.new(
        version: 1,
        id: "extract-id-1",
        dataset_id: "test-ds1",
        steps: [
          %{
            "step" => "Extract.Http.Get",
            "url" => "http://localhost:#{bypass.port}/file.csv"
          },
          %{
            "step" => "Decode.Csv",
            "headers" => ["A", "B", "C"]
          }
        ]
      )

    Brook.Test.send(@instance, "gather:extract:start", "testing", extract)

    # TODO
  end
end

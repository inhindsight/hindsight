defmodule GatherTest do
  use ExUnit.Case
  import Mox
  import Definition.Events, only: [extract_start: 0]

  @instance Gather.Application.instance()
  @moduletag capture_log: true

  alias Gather.Extraction

  setup :set_mox_global
  setup :verify_on_exit!

  setup do
    [bypass: Bypass.open()]
  end

  test "extract csv file", %{bypass: bypass} do
    test = self()
    {:ok, dummy_process} = Agent.start_link(fn -> :dummy_process end)

    Bypass.expect(bypass, "GET", "/file.csv", fn conn ->
      Plug.Conn.resp(conn, 200, "one,two,three\nfour,five,six")
    end)

    Gather.WriterMock
    |> expect(:start_link, fn args ->
      send(test, {:start_link, args})
      {:ok, dummy_process}
    end)
    |> expect(:write, fn server, messages ->
      send(test, {:write, server, messages})
      :ok
    end)

    extract =
      Extract.new!(
        version: 1,
        id: "extract-id-1",
        dataset_id: "test-ds1",
        name: "Johnny",
        steps: [
          %{
            "step" => "Http.Get",
            "url" => "http://localhost:#{bypass.port}/file.csv"
          },
          %{
            "step" => "Decode.Csv",
            "headers" => ["A", "B", "C"]
          }
        ]
      )

    Brook.Test.send(@instance, extract_start(), "testing", extract)

    assert_receive {:write, ^dummy_process, messages}, 5_000
    assert messages == [
      %{"A" => "one", "B" => "two", "C" => "three"},
      %{"A" => "four", "B" => "five", "C" => "six"}
    ]

    assert extract == Extraction.Store.get!(extract.id)
  end
end

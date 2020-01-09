defmodule GatherTest do
  use Gather.Case
  import Mox
  import Definition.Events, only: [extract_start: 0, extract_end: 0]
  import AssertAsync

  @instance Gather.Application.instance()
  @moduletag capture_log: true

  alias Gather.Extraction

  setup :set_mox_global
  setup :verify_on_exit!

  setup do
    Brook.Test.clear_view_state(@instance, "extractions")
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

  test "removes stored extraction on #{extract_end()}" do
    extract =
      Extract.new!(
        id: "extract-45",
        dataset_id: "ds45",
        name: "get_some_data",
        steps: []
      )

    Brook.Test.with_event(@instance, fn ->
      Extraction.Store.persist(extract)
    end)

    Brook.Test.send(@instance, extract_end(), "testing", extract)

    assert_async do
      assert nil == Extraction.Store.get!(extract.id)
    end
  end
end

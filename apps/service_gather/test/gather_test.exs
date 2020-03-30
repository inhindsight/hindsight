defmodule GatherTest do
  use Gather.Case
  import Events, only: [extract_start: 0, extract_end: 0]
  import AssertAsync
  require Temp.Env
  import Mox

  setup :set_mox_global

  Temp.Env.modify([
    %{
      app: :service_gather,
      key: Gather.Extraction.SourceStream.SourceHandler,
      set: [
        dlq: DlqMock
      ]
    }
  ])

  @instance Gather.Application.instance()
  @moduletag capture_log: true

  alias Gather.Extraction

  setup do
    test = self()
    DlqMock
    |> stub(:write, fn messages ->
      send(test, {:dlq, messages})
      :ok
    end)

    on_exit(fn ->
      Gather.Extraction.Supervisor.kill_all_children()
    end)

    :ok
  end

  setup do
    Brook.Test.clear_view_state(@instance, "extractions")
    [bypass: Bypass.open()]
  end

  test "extract csv file", %{bypass: bypass} do
    Bypass.expect(bypass, "GET", "/file.csv", fn conn ->
      Plug.Conn.resp(conn, 200, "one,two,three\nfour,five,six")
    end)

    extract =
      Extract.new!(
        version: 1,
        id: "extract-id-1",
        dataset_id: "test-ds1",
        subset_id: "Johnny",
        source: Extractor.new!(
          steps: [
            Extract.Http.Get.new!(url: "http://localhost:#{bypass.port}/file.csv")
          ]
        ),
        decoder: Decoder.Csv.new!(headers: ["A", "B", "C"]),
        destination: Destination.Fake.new!(),
        dictionary: [
          Dictionary.Type.String.new!(name: "A"),
          Dictionary.Type.String.new!(name: "b"),
          Dictionary.Type.String.new!(name: "C")
        ]
      )

    Brook.Test.send(@instance, extract_start(), "testing", extract)

    assert_receive {:destination_start_link, _}, 5_000
    assert_receive {:destination_write, messages}, 5_000

    assert messages == [
             %{"a" => "one", "b" => "two", "c" => "three"},
             %{"a" => "four", "b" => "five", "c" => "six"}
           ]

    assert extract == Extraction.Store.get!(extract.dataset_id, extract.subset_id)

    Process.sleep(5_000)
  end

  test "marks stored extraction done on #{extract_end()}" do
    extract =
      Extract.new!(
        id: "extract-45",
        dataset_id: "ds45",
        subset_id: "get_some_data",
        source: Source.Fake.new!(),
        decoder: Decoder.Json.new!([]),
        destination: Destination.Fake.new!()
      )

    Brook.Test.with_event(@instance, fn ->
      Extraction.Store.persist(extract)
    end)

    Brook.Test.send(@instance, extract_end(), "testing", extract)

    assert_async do
      assert true == Extraction.Store.done?(extract)
    end
  end

  test "sends extract_end on extract completion" do
    source = Source.Fake.new!()

    extract =
      Extract.new!(
        id: "extract-45",
        dataset_id: "ds45",
        subset_id: "get_some_data",
        source: source,
        decoder: %Decoder.Noop{},
        destination: Destination.Fake.new!()
      )

    Brook.Test.send(@instance, extract_start(), "testing", extract)

    assert_receive {:source_start_link, _, _}, 2_000

    Source.Fake.stop(source)

    assert_receive {:brook_event, %{type: extract_end(), data: ^extract}}, 5_000
  end
end

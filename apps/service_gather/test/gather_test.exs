defmodule GatherTest do
  use Gather.Case
  import Mox
  import Events, only: [extract_start: 0, extract_end: 0]
  import AssertAsync
  require Temp.Env

  @instance Gather.Application.instance()
  @moduletag capture_log: true

  alias Gather.Extraction

  Temp.Env.modify([
    %{
      app: :service_gather,
      key: Gather.Extraction,
      update: fn config ->
        Keyword.put(config, :writer, Gather.WriterMock)
      end
    }
  ])

  setup :set_mox_global
  setup :verify_on_exit!

  setup do
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
    test = self()
    {:ok, dummy_process} = Agent.start_link(fn -> :dummy_process end)

    Bypass.expect(bypass, "GET", "/file.csv", fn conn ->
      Plug.Conn.resp(conn, 200, "one,two,three\nfour,five,six")
    end)

    Gather.WriterMock
    |> stub(:start_link, fn args ->
      send(test, {:start_link, args})
      {:ok, dummy_process}
    end)
    |> stub(:write, fn server, messages, opts ->
      send(test, {:write, server, messages, opts})
      :ok
    end)

    extract =
      Extract.new!(
        version: 1,
        id: "extract-id-1",
        dataset_id: "test-ds1",
        subset_id: "Johnny",
        destination: "topic-1",
        steps: [
          Extract.Http.Get.new!(url: "http://localhost:#{bypass.port}/file.csv"),
          Extract.Decode.Csv.new!(headers: ["A", "B", "C"])
        ],
        dictionary: [
          Dictionary.Type.String.new!(name: "A"),
          Dictionary.Type.String.new!(name: "b"),
          Dictionary.Type.String.new!(name: "C")
        ]
      )

    Brook.Test.send(@instance, extract_start(), "testing", extract)

    assert_receive {:write, ^dummy_process, messages, [extract: ^extract]}, 5_000

    assert messages == [
             %{"a" => "one", "b" => "two", "c" => "three"},
             %{"a" => "four", "b" => "five", "c" => "six"}
           ]

    assert extract == Extraction.Store.get!(extract.dataset_id, extract.subset_id)
  end

  test "removes stored extraction on #{extract_end()}" do
    extract =
      Extract.new!(
        id: "extract-45",
        dataset_id: "ds45",
        subset_id: "get_some_data",
        destination: "topic1",
        steps: []
      )

    Brook.Test.with_event(@instance, fn ->
      Extraction.Store.persist(extract)
    end)

    Brook.Test.send(@instance, extract_end(), "testing", extract)

    assert_async do
      assert nil == Extraction.Store.get!(extract.dataset_id, extract.subset_id)
    end
  end

  test "sends extract_end on extract completion" do
    test = self()
    {:ok, dummy_process} = Agent.start_link(fn -> :dummy_process end)

    extract =
      Extract.new!(
        id: "extract-45",
        dataset_id: "ds45",
        subset_id: "get_some_data",
        destination: "topic1",
        steps: []
      )

    Gather.WriterMock
    |> expect(:start_link, fn args ->
      send(test, {:start_link, args})
      {:ok, dummy_process}
    end)

    Brook.Test.send(@instance, extract_start(), "testing", extract)

    assert_receive {:brook_event, %{type: extract_end(), data: ^extract}}, 5_000
  end
end

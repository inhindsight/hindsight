defmodule Platform.Runner.PerformanceTest do
  use ExUnit.Case
  use Divo
  import AssertAsync

  @moduletag performance: true, divo: true

  setup do
    Logger.configure(level: :info)
    bp = Bypass.open()

    data = File.read!("perf2.data")

    Bypass.stub(bp, "GET", "/file.csv", fn conn ->
      Plug.Conn.resp(conn, 200, data)
    end)

    [bypass: bp]
  end

  @tag timeout: :infinity
  test "performance", %{bypass: bypass} do
    Benchee.run(
      %{
        "csv" => fn -> csv(port: bypass.port) end
      },
      warmup: 0
    )
  end

  defp csv(opts) do
    dictionary = Enum.map(1..100, fn i -> Dictionary.Type.String.new!(name: "string_#{i}") end)
    headers = Enum.map(dictionary, &Map.get(&1, :name))

    extract =
      Extract.new!(
        id: "perf-csv-extract-1",
        dataset_id: "perf-csv-ds",
        subset_id: "default",
        destination: "perf-csv",
        steps: [
          Extract.Http.Get.new!(url: "http://localhost:#{Keyword.fetch!(opts, :port)}/file.csv"),
          Extract.Decode.Csv.new!(headers: headers)
        ],
        dictionary: dictionary
      )

    Gather.Application.instance()
    |> Events.send_extract_start("performance", extract)

    transform =
      Transform.new!(
        id: "perf-csv-tranform-1",
        dataset_id: "perf-csv-ds",
        subset_id: "default",
        dictionary: dictionary,
        steps: [
        ]
      )

    Gather.Application.instance()
    |> Events.send_transform_define("performance", transform)

    persist =
      Load.Persist.new!(
        id: "perf-csv-persist-1",
        dataset_id: "perf-csv-ds",
        subset_id: "default",
        source: "perf-csv",
        destination: "perf_csv"
      )

    Gather.Application.instance()
    |> Events.send_load_persist_start("performance", persist)

    session =
      Prestige.new_session(
        url: "http://localhost:8080",
        user: "hindsight",
        catalog: "hive",
        schema: "default"
      )

    assert_async sleep: 1_000, max_tries: 1_000, debug: true do
      with {:ok, result} <- Prestige.query(session, "select count(*) from perf_csv") do
        assert result.rows == [[100_000]]
      else
        {:error, reason} -> flunk(inspect(reason))
      end
    end
  end
end

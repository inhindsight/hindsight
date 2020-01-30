defmodule Platform.Runner.PerformanceTest do
  use ExUnit.Case
  use Divo
  import AssertAsync

  @moduletag performance: true, divo: true

  setup do
    bp = Bypass.open()

    Bypass.stub(bp, "GET", "/file.csv", fn conn ->
      Plug.Conn.resp(conn, 200, "a,1\nb,2\nc,3")
    end)

    [bypass: bp]
  end

  test "performance", %{bypass: bypass} do
    Benchee.run(
      %{
        "csv" => fn -> csv(port: bypass.port) end
      },
      warmup: 0
    )
  end

  defp csv(opts) do
    extract =
      Extract.new!(
        id: "perf-csv-extract-1",
        dataset_id: "perf-csv-ds",
        name: "default",
        destination: "perf-csv",
        steps: [
          Extract.Http.Get.new!(url: "http://localhost:#{Keyword.fetch!(opts, :port)}/file.csv"),
          Extract.Decode.Csv.new!(headers: ["letter", "number"])
        ],
        dictionary: [
          Dictionary.Type.String.new!(name: "letter"),
          Dictionary.Type.String.new!(name: "number")
        ]
      )

    Gather.Application.instance()
    |> Events.send_extract_start("performance", extract)

    transform =
      Transform.new!(
        id: "perf-csv-tranform-1",
        dataset_id: "perf-csv-ds",
        dictionary: [
          Dictionary.Type.String.new!(name: "letter"),
          Dictionary.Type.String.new!(name: "number")
        ],
        steps: [
          Transformer.MoveField.new!(from: "letter", to: "single_letter")
        ]
      )

    Gather.Application.instance()
    |> Events.send_transform_define("performance", transform)

    persist =
      Load.Persist.new!(
        id: "perf-csv-persist-1",
        dataset_id: "perf-csv-ds",
        name: "persist",
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

    assert_async sleep: 500, max_tries: 100, debug: true do
      with {:ok, result} <-
             Prestige.query(session, "select * from perf_csv order by single_letter") do
        assert Prestige.Result.as_maps(result) == [
                 %{"single_letter" => "a", "number" => "1"},
                 %{"single_letter" => "b", "number" => "2"},
                 %{"single_letter" => "c", "number" => "3"}
               ]
      else
        {:error, reason} -> flunk(inspect(reason))
      end
    end
  end
end

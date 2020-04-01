defmodule Platform.Runner.PerformanceTest do
  use ExUnit.Case
  use Divo
  import AssertAsync

  @moduletag performance: true, divo: true

  setup do
    Logger.configure(level: :info)
    bp = Bypass.open()

    data = File.read!("perf.data")

    Bypass.stub(bp, "GET", "/file.csv", fn conn ->
      Plug.Conn.resp(conn, 200, data)
    end)

    [bypass: bp]
  end

  @tag timeout: :infinity
  test "performance through persist", %{bypass: bypass} do
    Benchee.run(
      %{
        "csv_persist" => fn -> persist_csv(port: bypass.port, dataset: "persisted") end,
        "csv_broadcast" => fn -> broadcast_csv(port: bypass.port, dataset: "broadcasted") end
      },
      warmup: 0
    )
  end

  defp persist_csv(opts) do
    ds = Keyword.fetch!(opts, :dataset)
    csv(opts)

    persist =
      Load.Persist.new!(
        id: "perf-#{ds}-persist-1",
        dataset_id: "perf-#{ds}",
        subset_id: "default",
        source: Kafka.Topic.new!(
          endpoints: [localhost: 9092],
          name: "perf-#{ds}-csv",
          partitions: 4,
          partitioner: :md5
        ),
        destination: Presto.Table.new1(
          url: "http://localhost:8080",
          name: "perf_#{ds}_persist"
        )
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
      with {:ok, result} <- Prestige.query(session, "select count(*) from perf_#{ds}_persist") do
        assert result.rows == [[100_000]]
      else
        {:error, reason} -> flunk(inspect(reason))
      end
    end
  end

  defp broadcast_csv(opts) do
    ds = Keyword.fetch!(opts, :dataset)
    csv(opts)

    broadcast =
      Load.Broadcast.new!(
        id: "perf-#{ds}-broadcast-1",
        dataset_id: "perf-#{ds}",
        subset_id: "default",
        source: "perf-#{ds}-csv",
        destination: "perf_#{ds}_broadcast"
      )

    {:ok, _} =
      PlatformRunner.BroadcastClient.join(
        caller: self(),
        topic: broadcast.destination
      )

    Gather.Application.instance()
    |> Events.send_load_broadcast_start("performance", broadcast)

    assert_receive %{"letter" => "b", "number" => 100_000}, 90_000
  end

  defp csv(opts) do
    # dictionary = Enum.map(1..100, fn i -> Dictionary.Type.String.new!(name: "string_#{i}") end)
    # headers = Enum.map(dictionary, &Map.get(&1, :name))
    ds = Keyword.fetch!(opts, :dataset)

    dictionary =
      Dictionary.from_list([
        Dictionary.Type.String.new!(name: "letter"),
        Dictionary.Type.Integer.new!(name: "number")
      ])

    headers = ["letter", "number"]

    extract =
      Extract.new!(
        id: "perf-#{ds}-extract-1",
        dataset_id: "perf-#{ds}",
        subset_id: "default",
        destination: "perf-#{ds}-csv",
        steps: [
          Extract.Http.Get.new!(url: "http://localhost:#{Keyword.fetch!(opts, :port)}/file.csv"),
          Extract.Decode.Csv.new!(headers: headers)
        ],
        dictionary: dictionary,
        message_key: ["letter"],
        config: %{
          "kafka" => %{
            "partitions" => 4,
            "partitioner" => "md5"
          }
        }
      )

    Gather.Application.instance()
    |> Events.send_extract_start("performance", extract)

    transform =
      Transform.new!(
        id: "perf-#{ds}-tranform-1",
        dataset_id: "perf-#{ds}",
        subset_id: "default",
        dictionary: dictionary,
        Steps: []
      )

    Gather.Application.instance()
    |> Events.send_transform_define("performance", transform)
  end
end

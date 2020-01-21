defmodule PlatformRunner.EndToEndTest do
  use ExUnit.Case
  use Divo

  import AssertAsync
  alias PlatformRunner.BroadcastClient

  @kafka [localhost: 9092]
  @moduletag e2e: true, divo: true

  test "orchestrated CSV" do
    bp = Bypass.open()

    Bypass.stub(bp, "GET", "/file.csv", fn conn ->
      Plug.Conn.resp(conn, 200, "a,1\nb,2\nc,3")
    end)

    schedule =
      Schedule.new!(
        id: "e2e-csv-schedule-1",
        dataset_id: "e2e-csv-ds",
        cron: "*/10 * * * * * *",
        extract:
          Extract.new!(
            version: 1,
            id: "e2e-csv-extract-1",
            dataset_id: "e2e-csv-ds",
            name: "gather",
            destination: "e2e-csv-gather",
            steps: [
              Extract.Http.Get.new!(url: "http://localhost:#{bp.port}/file.csv"),
              Extract.Decode.Csv.new!(headers: ["letter", "number"])
            ]
          ),
        transform:
          Transform.new!(
            id: "e2e-csv-tranform-1",
            dataset_id: "e2e-csv-ds",
            dictionary: [],
            steps: []
          ),
        load: [
          Load.Broadcast.new!(
            id: "e2e-csv-broadcast-1",
            dataset_id: "e2e-csv-ds",
            name: "broadcast",
            source: "e2e-csv-gather",
            destination: "e2e_csv_broadcast",
            schema: [
              %Dictionary.Type.String{name: "letter"},
              %Dictionary.Type.String{name: "number"}
            ]
          ),
          Load.Persist.new!(
            id: "e2e-csv-persist-1",
            dataset_id: "e2e-csv-ds",
            name: "persist",
            source: "e2e-csv-gather",
            destination: "e2e_csv",
            schema: [
              %Dictionary.Type.String{name: "letter"},
              %Dictionary.Type.String{name: "number"}
            ]
          )
        ]
      )

    assert {:ok, pid} = BroadcastClient.join(caller: self(), topic: "e2e_csv_broadcast")

    Orchestrate.Application.instance()
    |> Definition.Events.send_schedule_start("e2e", schedule)

    assert_async debug: true, sleep: 500 do
      assert Orchestrate.Scheduler.find_job(:"e2e-csv-schedule-1") != nil
    end

    assert_async debug: true, sleep: 1_000, max_tries: 30 do
      assert {:ok, _, messages} = Elsa.fetch(@kafka, "e2e-csv-gather")

      assert [["a", "1"], ["b", "2"], ["c", "3"]] =
               Enum.map(messages, fn %{value: val} -> Jason.decode!(val) end)
               |> Enum.map(&Map.values(&1))
    end

    assert_receive %{"letter" => "a", "number" => "1"}, 11_000
    assert_receive %{"letter" => "b", "number" => "2"}, 1_000
    assert_receive %{"letter" => "c", "number" => "3"}, 1_000

    BroadcastClient.kill(pid)

    session =
      Prestige.new_session(
        url: "http://localhost:8080",
        user: "doti",
        catalog: "hive",
        schema: "default"
      )

    assert_async sleep: 1_000, max_tries: 30, debug: true do
      with {:ok, result} <- Prestige.query(session, "select * from e2e_csv order by letter") do
        assert Prestige.Result.as_maps(result) == [
                 %{"letter" => "a", "number" => "1"},
                 %{"letter" => "b", "number" => "2"},
                 %{"letter" => "c", "number" => "3"}
               ]
      else
        {:error, reason} -> flunk(inspect(reason))
      end
    end
  end

  describe "JSON" do
    test "gathered" do
      bp = Bypass.open()

      data = ~s|{"name":"LeBron","number":23,"teammates":[{"name":"Kyrie"},{"name":"Kevin"}]}|

      Bypass.expect(bp, "GET", "/json", fn conn ->
        Plug.Conn.resp(conn, 200, data)
      end)

      extract =
        Extract.new!(
          version: 1,
          id: "e2e-json-extract-1",
          dataset_id: "e2e-json-ds",
          name: "gather",
          destination: "e2e-json-gather",
          steps: [
            Extract.Http.Get.new!(url: "http://localhost:#{bp.port}/json"),
            Extract.Decode.Json.new!([])
          ]
        )

      Gather.Application.instance()
      |> Definition.Events.send_extract_start("e2e-json", extract)

      assert_async debug: true, sleep: 500 do
        assert {:ok, _, [message]} = Elsa.fetch(@kafka, "e2e-json-gather")
        assert message.value == data
      end
    end

    test "broadcasted" do
      load =
        Load.Broadcast.new!(
          id: "e2e-json-broadcast-1",
          dataset_id: "e2e-json-ds",
          name: "broadcast",
          source: "e2e-json-gather",
          destination: "e2e_json_broadcast",
          schema: [
            %Dictionary.Type.String{name: "name"},
            %Dictionary.Type.Integer{name: "number"},
            %Dictionary.Type.List{
              name: "teammates",
              item_type: Dictionary.Type.Map,
              fields: [%Dictionary.Type.String{name: "name"}]
            }
          ]
        )

      assert {:ok, pid} = BroadcastClient.join(caller: self(), topic: load.destination)

      Broadcast.Application.instance()
      |> Definition.Events.send_load_broadcast_start("e2e-json", load)

      assert_receive %{
                       "name" => "LeBron",
                       "number" => 23,
                       "teammates" => [%{"name" => "Kyrie"}, %{"name" => "Kevin"}]
                     },
                     1_000

      BroadcastClient.kill(pid)
    end

    test "persisted" do
      load =
        Load.Persist.new!(
          id: "e2e-json-persist-1",
          dataset_id: "e2e-json-ds",
          name: "persist",
          source: "e2e-json-gather",
          destination: "e2e_json",
          schema: [
            %Dictionary.Type.String{name: "name"},
            %Dictionary.Type.Integer{name: "number"},
            %Dictionary.Type.List{
              name: "teammates",
              item_type: Dictionary.Type.Map,
              fields: [%Dictionary.Type.String{name: "name"}]
            }
          ]
        )

      Persist.Application.instance()
      |> Definition.Events.send_load_persist_start("e2e-json", load)

      session =
        Prestige.new_session(
          url: "http://localhost:8080",
          user: "doti",
          catalog: "hive",
          schema: "default"
        )

      assert_async sleep: 1_000, max_tries: 30, debug: true do
        with {:ok, result} <- Prestige.query(session, "select * from e2e_json") do
          assert Prestige.Result.as_maps(result) == [
                   %{
                     "name" => "LeBron",
                     "number" => 23,
                     "teammates" => [
                       %{"name" => "Kyrie"},
                       %{"name" => "Kevin"}
                     ]
                   }
                 ]
        else
          {:error, reason} -> flunk(inspect(reason))
        end
      end
    end
  end
end

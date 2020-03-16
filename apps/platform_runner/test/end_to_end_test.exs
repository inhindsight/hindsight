defmodule PlatformRunner.EndToEndTest do
  use ExUnit.Case
  use Divo

  import AssertAsync
  alias PlatformRunner.{BroadcastClient, AcquireClient}

  @kafka [localhost: 9092]
  @moduletag e2e: true, divo: true, timeout: :infinity

  test "orchestrated CSV" do
    bp = Bypass.open()

    Bypass.stub(bp, "GET", "/file.csv", fn conn ->
      Plug.Conn.resp(conn, 200, "a,1,0.1\nb,2,0.2\nc,3,")
    end)

    schedule =
      Schedule.new!(
        id: "e2e-csv-schedule-1",
        dataset_id: "e2e-csv-ds",
        subset_id: "csv-subset",
        cron: "*/10 * * * * * *",
        extract:
          Extract.new!(
            version: 1,
            id: "e2e-csv-extract-1",
            dataset_id: "e2e-csv-ds",
            subset_id: "csv-subset",
            destination: "e2e-csv-gather",
            steps: [
              Extract.Http.Get.new!(url: "http://localhost:#{bp.port}/file.csv"),
              Extract.Decode.Csv.new!(headers: ["letter", "number", "float"])
            ],
            dictionary: [
              Dictionary.Type.String.new!(name: "letter"),
              Dictionary.Type.String.new!(name: "number"),
              Dictionary.Type.Float.new!(name: "float")
            ]
          ),
        transform:
          Transform.new!(
            id: "e2e-csv-tranform-1",
            dataset_id: "e2e-csv-ds",
            subset_id: "csv-subset",
            dictionary: [
              Dictionary.Type.String.new!(name: "letter"),
              Dictionary.Type.String.new!(name: "number"),
              Dictionary.Type.Float.new!(name: "float")
            ],
            steps: [
              Transform.MoveField.new!(from: "letter", to: "single_letter")
            ]
          ),
        load: [
          Load.Broadcast.new!(
            id: "e2e-csv-broadcast-1",
            dataset_id: "e2e-csv-ds",
            subset_id: "csv-subset",
            source: "e2e-csv-gather",
            destination: "e2e_csv_broadcast"
          ),
          Load.Persist.new!(
            id: "e2e-csv-persist-1",
            dataset_id: "e2e-csv-ds",
            subset_id: "csv-subset",
            source: "e2e-csv-gather",
            destination: "e2e__csv"
          )
        ]
      )

    assert {:ok, pid} = BroadcastClient.join(caller: self(), topic: "e2e_csv_broadcast")

    Orchestrate.Application.instance()
    |> Events.send_schedule_start("e2e", schedule)

    assert_async debug: true, sleep: 500 do
      assert Orchestrate.Scheduler.find_job(:"e2e-csv-ds__csv-subset") != nil
    end

    assert_async debug: true, sleep: 1_000, max_tries: 30 do
      assert Elsa.topic?(@kafka, "e2e-csv-gather")
      assert {:ok, _, messages} = Elsa.fetch(@kafka, "e2e-csv-gather")

      assert [[0.1, "a", "1"], [0.2, "b", "2"], [nil, "c", "3"]] =
               Enum.map(messages, fn %{value: val} -> Jason.decode!(val) end)
               |> Enum.map(&Map.values(&1))
    end

    assert_receive %{"single_letter" => "a", "number" => "1", "float" => 0.1}, 60_000
    assert_receive %{"single_letter" => "b", "number" => "2", "float" => 0.2}, 1_000
    assert_receive %{"single_letter" => "c", "number" => "3", "float" => nil}, 1_000

    BroadcastClient.kill(pid)

    session =
      Prestige.new_session(
        url: "http://localhost:8080",
        user: "doti",
        catalog: "hive",
        schema: "default"
      )

    assert_async sleep: 1_000, max_tries: 60, debug: true do
      with {:ok, result} <-
             Prestige.query(session, "select * from e2e__csv order by single_letter") do
        assert Enum.member?(Prestige.Result.as_maps(result), %{
                 "single_letter" => "a",
                 "number" => "1",
                 "float" => 0.1
               })

        assert Enum.member?(Prestige.Result.as_maps(result), %{
                 "single_letter" => "b",
                 "number" => "2",
                 "float" => 0.2
               })

        assert Enum.member?(Prestige.Result.as_maps(result), %{
                 "single_letter" => "c",
                 "number" => "3",
                 "float" => nil
               })
      else
        {:error, reason} -> flunk(inspect(reason))
      end
    end

    expected = %{"single_letter" => "b"}

    assert {:ok, [^expected | _]} =
             AcquireClient.data("/e2e-csv-ds/csv-subset?fields=single_letter&filter=number=2")

    assert {:ok, [_, _]} = AcquireClient.data("/e2e-csv-ds/csv-subset?limit=2")
  end

  describe "JSON" do
    test "gathered" do
      bp = Bypass.open()

      data =
        ~s|{"name":"LeBron","number":23,"popularity":null,"teammates":[{"name":"Kyrie"},{"name":"Kevin"}]}|

      Bypass.expect(bp, "GET", "/json", fn conn ->
        Plug.Conn.resp(conn, 200, data)
      end)

      extract =
        Extract.new!(
          version: 1,
          id: "e2e-json-extract-1",
          dataset_id: "e2e-json-ds",
          subset_id: "json-subset",
          destination: "e2e-json-gather",
          steps: [
            Extract.Http.Get.new!(url: "http://localhost:#{bp.port}/json"),
            Extract.Decode.Json.new!([])
          ],
          dictionary: [
            Dictionary.Type.String.new!(name: "name"),
            Dictionary.Type.Integer.new!(name: "number"),
            Dictionary.Type.Float.new!(name: "popularity"),
            Dictionary.Type.List.new!(
              name: "teammates",
              item_type:
                Dictionary.Type.Map.new!(
                  name: "in_list",
                  dictionary: [
                    Dictionary.Type.String.new!(name: "name")
                  ]
                )
            )
          ]
        )

      Gather.Application.instance()
      |> Events.send_extract_start("e2e-json", extract)

      transform =
        Transform.new!(
          id: "e2e-json-transform-1",
          dataset_id: "e2e-json-ds",
          subset_id: "json-subset",
          dictionary: [
            Dictionary.Type.String.new!(name: "name"),
            Dictionary.Type.Integer.new!(name: "number"),
            Dictionary.Type.Float.new!(name: "popularity"),
            Dictionary.Type.List.new!(
              name: "teammates",
              item_type:
                Dictionary.Type.Map.new!(
                  name: "in_list",
                  dictionary: [
                    Dictionary.Type.String.new!(name: "name")
                  ]
                )
            )
          ],
          steps: []
        )

      Gather.Application.instance()
      |> Events.send_transform_define("e2e-json", transform)

      assert_async debug: true, sleep: 500 do
        assert Elsa.topic?(@kafka, "e2e-json-gather")
        assert {:ok, _, [message]} = Elsa.fetch(@kafka, "e2e-json-gather")
        assert message.value == data
      end
    end

    test "broadcasted" do
      load =
        Load.Broadcast.new!(
          id: "e2e-json-broadcast-1",
          dataset_id: "e2e-json-ds",
          subset_id: "json-subset",
          source: "e2e-json-gather",
          destination: "e2e_json_broadcast"
        )

      assert {:ok, pid} = BroadcastClient.join(caller: self(), topic: load.destination)

      Broadcast.Application.instance()
      |> Events.send_load_broadcast_start("e2e-json", load)

      assert_receive %{
                       "name" => "LeBron",
                       "number" => 23,
                       "popularity" => nil,
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
          subset_id: "json-subset",
          source: "e2e-json-gather",
          destination: "e2e__json"
        )

      Persist.Application.instance()
      |> Events.send_load_persist_start("e2e-json", load)

      session =
        Prestige.new_session(
          url: "http://localhost:8080",
          user: "doti",
          catalog: "hive",
          schema: "default"
        )

      assert_async sleep: 1_000, max_tries: 30, debug: true do
        with {:ok, result} <- Prestige.query(session, "select * from e2e__json") do
          assert Prestige.Result.as_maps(result) == [
                   %{
                     "name" => "LeBron",
                     "number" => 23,
                     "popularity" => nil,
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

    test "acquired" do
      expected = %{
        "name" => "LeBron",
        "number" => 23,
        "popularity" => nil,
        "teammates" => [
          %{"name" => "Kyrie"},
          %{"name" => "Kevin"}
        ]
      }

      assert {:ok, [^expected]} = AcquireClient.data("/e2e-json-ds/json-subset")
    end
  end

  describe "Pushed data" do
    test "pushed" do
      data = [
        ~s|{"name":"bob","ts":"2019-12-20 01:01:01"}|,
        ~s|{"name":"steve","ts":"2019-12-29 02:02:02"}|,
        ~s|{"name":"mike","ts":"2020-01-05 03:03:03"}|,
        ~s|{"name":"doug","ts":"2020-01-16 04:04:04"}|,
        ~s|{"name":"alex","ts":"2020-02-18 05:05:05"}|,
        ~s|{"name":"dave","ts":"2020-02-03 06:06:06"}|
      ]

      accept =
        Accept.new!(
          version: 1,
          id: "e2e-json-push-1",
          dataset_id: "e2e-push-ds",
          subset_id: "e2e-push-ss",
          destination: "e2e-push-receive",
          connection: Accept.Udp.new!(port: 6789)
        )

      Receive.Application.instance()
      |> Events.send_accept_start("e2e-push-json", accept)

      assert_async sleep: 500, max_tries: 10 do
        case Receive.Accept.Registry.whereis(:"#{accept.destination}_manager") do
          :undefined -> flunk("Process is not alive yet")
          pid when is_pid(pid) -> assert true == Process.alive?(pid)
        end
      end

      start_supervised({SourceUdpSocket, port: 6789, messages: data})

      assert_async debug: true, sleep: 1_000 do
        assert Elsa.topic?(@kafka, "e2e-push-receive")
        assert {:ok, _, messages} = Elsa.fetch(@kafka, "e2e-push-receive")
        assert length(messages) == 6
        retrieved_messages = Enum.map(messages, fn message -> message.value end)
        assert retrieved_messages == data
      end
    end

    test "gathered" do
      extract =
        Extract.new!(
          version: 1,
          id: "e2e-json-gather-1",
          dataset_id: "e2e-push-ds",
          subset_id: "e2e-push-ss",
          destination: "e2e-push-gather",
          steps: [
            Extract.Kafka.Subscribe.new!(endpoints: [localhost: 9092], topic: "e2e-push-receive"),
            Extract.Decode.JsonLines.new!([])
          ],
          dictionary: [
            Dictionary.Type.String.new!(name: "name"),
            Dictionary.Type.Timestamp.new!(name: "ts", format: "%Y-%m-%d %H:%M:%S")
          ]
        )

      Gather.Application.instance()
      |> Events.send_extract_start("e2e-push-json", extract)

      assert_async debug: true, max_tries: 15, sleep: 5_000 do
        assert Elsa.topic?(@kafka, "e2e-push-gather")
        assert {:ok, _, messages} = Elsa.fetch(@kafka, "e2e-push-gather")
        assert length(messages) == 6

        assert [
                 %{"name" => "bob", "ts" => "2019-12-20T01:01:01"},
                 %{"name" => "steve", "ts" => "2019-12-29T02:02:02"},
                 %{"name" => "mike", "ts" => "2020-01-05T03:03:03"},
                 %{"name" => "doug", "ts" => "2020-01-16T04:04:04"},
                 %{"name" => "alex", "ts" => "2020-02-18T05:05:05"},
                 %{"name" => "dave", "ts" => "2020-02-03T06:06:06"}
               ] == Enum.map(messages, fn %{value: val} -> Jason.decode!(val) end)
      end
    end

    test "acquired" do
      transform =
        Transform.new!(
          id: "e2e-push-transform-1",
          dataset_id: "e2e-push-ds",
          subset_id: "e2e-push-ss",
          steps: [],
          dictionary: [
            Dictionary.Type.String.new!(name: "name"),
            Dictionary.Type.Timestamp.new!(name: "ts", format: "%Y-%m-%d %H:%M:%S")
          ]
        )

      Gather.Application.instance()
      |> Events.send_transform_define("e2e-push-json", transform)

      persist =
        Load.Persist.new!(
          id: "e2e-push-persist-1",
          dataset_id: "e2e-push-ds",
          subset_id: "e2e-push-ss",
          source: "e2e-push-gather",
          destination: "e2e_push_ds"
        )

      Persist.Application.instance()
      |> Events.send_load_persist_start("e2e-push-json", persist)

      Process.sleep(5_000)

      expected = [
        %{"name" => "alex", "ts" => "2020-02-18 05:05:05.000"},
        %{"name" => "dave", "ts" => "2020-02-03 06:06:06.000"}
      ]

      assert_async sleep: 1_000, max_tries: 30, debug: true do
        assert {:ok, ^expected} =
                 AcquireClient.data("/e2e-push-ds/e2e-push-ss?after=2020-01-23T00:00:00")
      end
    end
  end
end

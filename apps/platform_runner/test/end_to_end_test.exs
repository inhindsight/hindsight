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
      Plug.Conn.resp(conn, 200, "a,1\nb,2\nc,3")
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
              Extract.Decode.Csv.new!(headers: ["letter", "number"])
            ],
            dictionary: [
              Dictionary.Type.String.new!(name: "letter"),
              Dictionary.Type.String.new!(name: "number")
            ]
          ),
        transform:
          Transform.new!(
            id: "e2e-csv-tranform-1",
            dataset_id: "e2e-csv-ds",
            subset_id: "csv-subset",
            dictionary: [
              Dictionary.Type.String.new!(name: "letter"),
              Dictionary.Type.String.new!(name: "number")
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
      assert {:ok, _, messages} = Elsa.fetch(@kafka, "e2e-csv-gather")

      assert [["a", "1"], ["b", "2"], ["c", "3"]] =
               Enum.map(messages, fn %{value: val} -> Jason.decode!(val) end)
               |> Enum.map(&Map.values(&1))
    end

    assert_receive %{"single_letter" => "a", "number" => "1"}, 45_000
    assert_receive %{"single_letter" => "b", "number" => "2"}, 1_000
    assert_receive %{"single_letter" => "c", "number" => "3"}, 1_000

    BroadcastClient.kill(pid)

    session =
      Prestige.new_session(
        url: "http://localhost:8080",
        user: "doti",
        catalog: "hive",
        schema: "default"
      )

    assert_async sleep: 1_000, max_tries: 30, debug: true do
      with {:ok, result} <-
             Prestige.query(session, "select * from e2e__csv order by single_letter") do
        assert Prestige.Result.as_maps(result) == [
                 %{"single_letter" => "a", "number" => "1"},
                 %{"single_letter" => "b", "number" => "2"},
                 %{"single_letter" => "c", "number" => "3"}
               ]
      else
        {:error, reason} -> flunk(inspect(reason))
      end
    end

    expected = %{"single_letter" => "b"}

    assert {:ok, [^expected]} =
             AcquireClient.data("/e2e-csv-ds/csv-subset?fields=single_letter&filter=number=2")

    assert {:ok, [_, _]} = AcquireClient.data("/e2e-csv-ds/csv-subset?limit=2")
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
          subset_id: "json-subset",
          destination: "e2e-json-gather",
          steps: [
            Extract.Http.Get.new!(url: "http://localhost:#{bp.port}/json"),
            Extract.Decode.Json.new!([])
          ],
          dictionary: [
            Dictionary.Type.String.new!(name: "name"),
            Dictionary.Type.Integer.new!(name: "number"),
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
        ~s|{"name":"bob","date":"2019-12-20"}|,
        ~s|{"name":"steve","date":"2019-12-29"}|,
        ~s|{"name":"mike","date":"2020-01-05"}|,
        ~s|{"name":"doug","date":"2020-01-16"}|,
        ~s|{"name":"alex","date":"2020-02-18"}|,
        ~s|{"name":"dave","date":"2020-02-03"}|
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

      start_supervised({SourceSocket, port: 6789, messages: data})

      assert_async debug: true, sleep: 1_000 do
        assert {:ok, _, messages} = Elsa.fetch(@kafka, "e2e-push-receive")
        assert length(messages) == 6
        retrieved_messages = Enum.map(messages, fn message -> message.value end)
        assert retrieved_messages == data
      end
    end

    # test "gathered" do
    #   extract =
    #     Extract.new!(
    #       version: 1,
    #       id: "e2e-json-gather-1",
    #       dataset_id: "e2e-push-ds",
    #       subset_id: "e2e-push-ss",
    #       destination: "e2e-push-gather",
    #       steps: [
    #         Extract.Kafka.Subscribe.new!(endpoints: [localhost: 9092], topic: "e2e-push-receive"),
    #         Extract.Decode.JsonLines.new!([])
    #       ],
    #       dictionary: [
    #         Dictionary.Type.String.new!(name: "name"),
    #         Dictionary.Type.Date.new!(name: "date", format: "%Y-%m-%d")
    #       ]
    #     )

    #   Gather.Application.instance()
    #   |> Events.send_extract_start("e2e-push-json", extract)

    #   assert_async debug: true, max_tries: 10, sleep: 5_000 do
    #     assert {:ok, _, messages} = Elsa.fetch(@kafka, "e2e-push-gather")
    #     assert length(messages) == 5

    #     assert [
    #              %{"name" => "bob", "date" => "2019-12-20"},
    #              %{"name" => "steve", "date" => "2019-12-29"},
    #              %{"name" => "mike", "date" => "2020-01-05"},
    #              %{"name" => "doug", "date" => "2020-01-16"},
    #              %{"name" => "alex", "date" => "2020-02-18"},
    #              %{"name" => "dave", "date" => "2020-02-03"}
    #            ] == Enum.map(messages, fn %{value: val} -> Jason.decode!(val) end)
    #   end
    # end
  end
end

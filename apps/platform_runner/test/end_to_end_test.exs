defmodule PlatformRunner.EndToEndTest do
  use ExUnit.Case
  use Divo

  import AssertAsync
  alias PlatformRunner.BroadcastClient

  @kafka [localhost: 9092]
  @moduletag e2e: true, divo: true

  describe "CSV" do
    test "gathered" do
      bp = Bypass.open()

      Bypass.expect(bp, "GET", "/file.csv", fn conn ->
        Plug.Conn.resp(conn, 200, "a,1\nb,2\nc,3")
      end)

      extract =
        Extract.new!(
          version: 1,
          id: "e2e-csv-extract-1",
          dataset_id: "e2e-csv-ds",
          name: "gather",
          destination: "e2e-csv-gather",
          steps: [
            %{"step" => "Http.Get", "url" => "http://localhost:#{bp.port}/file.csv"},
            %{"step" => "Decode.Csv", "headers" => ["letter", "number"]}
          ]
        )

      Gather.Application.instance()
      |> Definition.Events.send_extract_start("e2e-csv", extract)

      assert_async debug: true, sleep: 500 do
        assert {:ok, _, messages} = Elsa.fetch(@kafka, "e2e-csv-gather")

        assert [["a", "1"], ["b", "2"], ["c", "3"]] =
                 Enum.map(messages, fn %{value: val} -> Jason.decode!(val) end)
                 |> Enum.map(&Map.values(&1))
      end
    end

    test "broadcasted" do
      load =
        Load.Broadcast.new!(
          id: "e2e-csv-broadcast-1",
          dataset_id: "e2e-csv-ds",
          name: "broadcast",
          source: "e2e-csv-gather",
          destination: "e2e_csv_broadcast"
        )

      assert {:ok, pid} = BroadcastClient.join(caller: self(), topic: load.destination)

      Broadcast.Application.instance()
      |> Definition.Events.send_load_broadcast_start("e2e-csv", load)

      assert_receive %{"letter" => "a", "number" => "1"}, 1_000
      assert_receive %{"letter" => "b", "number" => "2"}, 1_000
      assert_receive %{"letter" => "c", "number" => "3"}, 1_000

      BroadcastClient.kill(pid)
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
            %{"step" => "Http.Get", "url" => "http://localhost:#{bp.port}/json"},
            %{"step" => "Decode.Json"}
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
          destination: "e2e_json_broadcast"
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
  end
end

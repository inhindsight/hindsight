defmodule PlatformRunner.EndToEndTest do
  use ExUnit.Case
  use Divo

  import AssertAsync
  import Definition.Events

  @kafka [localhost: 9092]
  @moduletag e2e: true, divo: true

  setup do
    [bypass: Bypass.open()]
  end

  describe "CSV" do
    test "can be gathered", %{bypass: bp} do
      Bypass.expect(bp, "GET", "/file.csv", fn conn ->
        Plug.Conn.resp(conn, 200, "a,1\nb,2\nc,3")
      end)

      extract =
        Extract.new!(
          version: 1,
          id: "e2e-csv-extract-1",
          dataset_id: "e2e-csv-ds",
          name: "name",
          destination: "e2e-csv-topic",
          steps: [
            %{"step" => "Http.Get", "url" => "http://localhost:#{bp.port}/file.csv"},
            %{"step" => "Decode.Csv", "headers" => ["letter", "number"]}
          ]
        )

      Gather.Application.instance()
      |> Brook.Event.send(extract_start(), "e2e-csv", extract)

      assert_async debug: true, sleep: 500 do
        assert {:ok, _, messages} = Elsa.fetch(@kafka, "e2e-csv-topic")

        assert [["a", "1"], ["b", "2"], ["c", "3"]] =
                 Enum.map(messages, fn %{value: val} -> Jason.decode!(val) end)
                 |> Enum.map(&Map.values(&1))
      end
    end
  end

  describe "JSON" do
    test "can be gathered", %{bypass: bp} do
      data =
        ~s|{"name":"LeBron","number":23,"teammates":[{"name":"Kyrie","number":2},{"name":"Kevin","number":0}]}|

      Bypass.expect(bp, "GET", "/json", fn conn ->
        Plug.Conn.resp(conn, 200, "[#{data}]")
      end)

      extract =
        Extract.new!(
          version: 1,
          id: "e2e-json-extract-1",
          dataset_id: "e2e-json-ds",
          name: "name",
          destination: "e2e-json-topic",
          steps: [
            %{"step" => "Http.Get", "url" => "http://localhost:#{bp.port}/json"},
            %{"step" => "Decode.Json"}
          ]
        )

      Gather.Application.instance()
      |> Brook.Event.send(extract_start(), "e2e-json", extract)

      assert_async debug: true, sleep: 500 do
        assert {:ok, _, [message]} = Elsa.fetch(@kafka, "e2e-json-topic")
        assert message.value == data
      end
    end
  end
end

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

  describe "CSV data" do
    test "gathered", %{bypass: bypass} do
      prefix = Application.get_env(:service_gather, :topic_prefix)

      Bypass.expect(bypass, "GET", "/file.csv", fn conn ->
        Plug.Conn.resp(conn, 200, "a,1\nb,2\nc,3")
      end)

      extract =
        Extract.new!(
          version: 1,
          id: "e2e-csv-extract-1",
          dataset_id: "e2e-csv-ds",
          name: "name",
          steps: [
            %{"step" => "Http.Get", "url" => "http://localhost:#{bypass.port}/file.csv"},
            %{"step" => "Decode.Csv", "headers" => ["letter", "number"]}
          ]
        )

      Gather.Application.instance()
      |> Brook.Event.send(extract_start(), "e2e-csv", extract)

      assert_async debug: true, sleep: 500  do
        assert {:ok, _, messages} = Elsa.fetch(@kafka, "#{prefix}-e2e-csv-ds-name")

        assert [["a", "1"], ["b", "2"], ["c", "3"]] =
                 Enum.map(messages, fn %{value: val} -> Jason.decode!(val) end)
                 |> Enum.map(&Map.values(&1))
      end
    end
  end
end

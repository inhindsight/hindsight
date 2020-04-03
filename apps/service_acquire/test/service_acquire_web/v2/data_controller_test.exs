defmodule AcquireWeb.V2.DataControllerTest do
  use AcquireWeb.ConnCase
  import Checkov
  use Placebo

  require Temp.Env

  Temp.Env.modify([
    %{
      app: :service_acquire,
      key: AcquireWeb.V2.DataController,
      set: [presto_client: Acquire.Db.Mock]
    }
  ])

  @instance Acquire.Application.instance()

  describe "select/2" do
    data_test "retrieves data", %{conn: conn} do
      regex = ~r/\/api\/v2\/data\/(?<dataset_id>\w+)(\/(?<subset_id>\w+))?/

      path_variables =
        Regex.named_captures(regex, path) |> Enum.reject(fn {_, v} -> v == "" end) |> Map.new()

      Brook.Test.with_event(@instance, fn ->
        Acquire.Dictionaries.persist(
          Transform.new!(
            id: "transform-1",
            dataset_id: path_variables["dataset_id"],
            subset_id: path_variables["subset_id"] || "default",
            dictionary: [
              Dictionary.Type.Wkt.Point.new!(name: "__wkt__"),
              Dictionary.Type.Timestamp.new!(name: "__timestamp__", format: "__format__")
            ],
            steps: []
          )
        )

        Acquire.Dictionaries.persist(
          Load.new!(
            id: "persist-1",
            dataset_id: path_variables["dataset_id"],
            subset_id: path_variables["subset_id"] || "default",
            source: Source.Fake.new!(),
            destination:
              Presto.Table.new!(
                url: "http://localhost:8080",
                name: "table_destination"
              )
          )
        )
      end)

      data = [%{"a" => 42}]
      Mox.expect(Acquire.Db.Mock, :execute, fn ^query, ^values -> {:ok, data} end)

      actual = get(conn, path) |> json_response(200)
      assert actual == data

      where [
        [:path, :query, :values],
        ["/api/v2/data/a/b", "SELECT * FROM table_destination", []],
        ["/api/v2/data/a", "SELECT * FROM table_destination", []],
        ["/api/v2/data/a?limit=1", "SELECT * FROM table_destination LIMIT 1", []],
        ["/api/v2/data/a/b?filter=a!=1", "SELECT * FROM table_destination WHERE a != ?", ["1"]],
        [
          "/api/v2/data/a/b?fields=c&filter=c=42,d=9000",
          "SELECT c FROM table_destination WHERE (c = ? AND d = ?)",
          ["42", "9000"]
        ],
        [
          "/api/v2/data/a/b?after=2020-01-01T00:00:00",
          "SELECT * FROM table_destination WHERE date_diff('millisecond', date_parse(?, '%Y-%m-%dT%H:%i:%S'), __timestamp__) > 0",
          ["2020-01-01T00:00:00"]
        ],
        [
          "/api/v2/data/a/b?before=2020-01-01T00:00:00",
          "SELECT * FROM table_destination WHERE date_diff('millisecond', date_parse(?, '%Y-%m-%dT%H:%i:%S'), __timestamp__) < 0",
          ["2020-01-01T00:00:00"]
        ],
        [
          "/api/v2/data/a/b?after=2020-01-01T00:00:00&before=2022-01-01T00:00:00",
          "SELECT * FROM table_destination WHERE (date_diff('millisecond', date_parse(?, '%Y-%m-%dT%H:%i:%S'), __timestamp__) > 0 AND date_diff('millisecond', date_parse(?, '%Y-%m-%dT%H:%i:%S'), __timestamp__) < 0)",
          ["2020-01-01T00:00:00", "2022-01-01T00:00:00"]
        ],
        [
          "/api/v2/data/a/b?boundary=1.0,2.0,3.0,4.0",
          "SELECT * FROM table_destination WHERE ST_Intersects(ST_Envelope(ST_LineString(array[ST_Point(?, ?), ST_Point(?, ?)])), ST_GeometryFromText(__wkt__))",
          [1.0, 2.0, 3.0, 4.0]
        ],
        [
          "/api/v2/data/a/b?filter=c>=42&boundary=1.0,2.0,3.0,4.0",
          "SELECT * FROM table_destination WHERE (c >= ? AND ST_Intersects(ST_Envelope(ST_LineString(array[ST_Point(?, ?), ST_Point(?, ?)])), ST_GeometryFromText(__wkt__)))",
          ["42", 1.0, 2.0, 3.0, 4.0]
        ]
      ]
    end
  end

  describe "query/2" do
    setup do
      Brook.Test.with_event(@instance, fn ->
        Acquire.Dictionaries.persist(
          Transform.new!(
            id: "transform-1",
            dataset_id: "dataset_id_1",
            subset_id: "subset_id_1",
            dictionary: [
              Dictionary.Type.Wkt.Point.new!(name: "__wkt__"),
              Dictionary.Type.Timestamp.new!(name: "__timestamp__", format: "__format__")
            ],
            steps: []
          )
        )

        Acquire.Dictionaries.persist(
          Load.new!(
            id: "persist-1",
            dataset_id: "dataset_id_1",
            subset_id: "subset_id_1",
            source: Source.Fake.new!(),
            destination:
              Presto.Table.new!(
                url: "http://localhost:8080",
                name: "table_destination"
              )
          )
        )
      end)
    end

    test "retrieves data", %{conn: conn} do
      data = [%{"a" => 42}]
      query = "SELECT * FROM table_destination"
      Mox.expect(Acquire.Db.Mock, :execute, fn ^query, [] -> {:ok, data} end)

      path = "/api/v2/data/"

      actual =
        conn
        |> put_req_header("content-type", "text/plain")
        |> post(path, query)
        |> json_response(200)

      assert actual == data
    end

    test "fails on invalid query", %{conn: conn} do
      data = ["Bad request"]
      query = "SULAKT * FROM table_destination"
      Mox.expect(Acquire.Db.Mock, :execute, fn ^query, [] -> {:error, data} end)

      path = "/api/v2/data/"

      actual =
        conn
        |> put_req_header("content-type", "text/plain")
        |> post(path, query)
        |> json_response(400)

      assert actual == data
    end
  end
end

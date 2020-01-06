defmodule Writer.PrestoIntTest do
  use ExUnit.Case
  use Divo

  @moduletag integration: true, divo: true, capture_log: true

  alias Writer.Presto

  @url "http://localhost:8080"

  test "something, something, presto" do
    table_schema = [
      {"name", "varchar"},
      {"age", "integer"},
      {"colors", "array(varchar)"},
      {"spouse", "row(name varchar, age integer, colors array(varchar))"}
    ]

    {:ok, pid} =
      Presto.start_link(
        url: @url,
        user: "testing",
        table: "table1",
        table_schema: table_schema,
        catalog: "hive",
        schema: "default"
      )

    Presto.write(pid, [
      %{
        "name" => "george",
        "age" => 21,
        "colors" => ["red", "blue"],
        "spouse" => [{"name", "shirley"}, {"age", 23}, {"colors", ["yellow", "green"]}]
      }
    ])

    session =
      Prestige.new_session(
        url: @url,
        user: "testing",
        catalog: "hive",
        schema: "default"
      )

    expected = [
      %{
        "name" => "george",
        "age" => 21,
        "colors" => ["red", "blue"],
        "spouse" => %{"name" => "shirley", "age" => 23, "colors" => ["yellow", "green"]}
      }
    ]

    result = Prestige.query!(session, "select * from table1")
    assert expected == Prestige.Result.as_maps(result)
  end
end

defmodule Writer.PrestoIntTest do
  use ExUnit.Case
  use Divo

  @moduletag integration: true, divo: true, capture_log: true

  alias Writer.Presto

  @url "http://localhost:8080"

  setup do
    Process.flag(:trap_exit, true)
    :ok
  end

  test "something, something, presto" do
    table_schema = [
      {"name", "varchar"},
      {"age", "integer"},
      {"colors", "array(varchar)"},
      {"spouse", "row(name varchar, age integer, colors array(varchar))"},
      {"friends", "array(row(name varchar, age integer))"}
    ]

    record = {"george", 21, ["red", "blue"], {"shirley", 23, ["yellow", "green"]}, [{"joe", 47}, {"frank", 51}]}

    {:ok, pid} =
      Presto.start_link(
        url: @url,
        user: "testing",
        table: "table1",
        table_schema: table_schema,
        catalog: "hive",
        schema: "default"
      )

    Presto.write(pid, [record])

    session =
      Prestige.new_session(
        url: @url,
        user: "testing",
        catalog: "hive",
        schema: "default"
      )

    on_exit(fn ->
      Prestige.execute!(session, "DELETE from table1")
    end)

    expected = [
      %{
        "name" => "george",
        "age" => 21,
        "colors" => ["red", "blue"],
        "spouse" => %{"name" => "shirley", "age" => 23, "colors" => ["yellow", "green"]},
        "friends" => [%{"name" => "joe", "age" => 47}, %{"name" => "frank", "age" => 51}]
      }
    ]

    result = Prestige.query!(session, "select * from table1")
    assert expected == Prestige.Result.as_maps(result)
  end
end

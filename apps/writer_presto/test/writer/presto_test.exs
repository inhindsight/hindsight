defmodule Writer.PrestoTest do
  use ExUnit.Case
  use Placebo

  alias Writer.Presto

  setup do
    Process.flag(:trap_exit, true)
    :ok
  end

  test "process should die if unable to create table" do
    allow Prestige.execute(any(), starts_with("CREATE TABLE")),
      return: {:error, "unable to create table"}

    result =
      Presto.start_link(
        url: "http://some.url",
        user: "testing",
        table_schema: [{"name", "varchar"}],
        table: "table1"
      )

    assert result == {:error, "unable to create table"}
  end

  test "write should return error tuple if unable to write messages" do
    allow Prestige.execute(any(), starts_with("CREATE TABLE")),
      return: {:ok, :result}

    allow Prestige.execute(any(), starts_with("INSERT INTO")), return: {:error, "failed to query"}

    {:ok, pid} =
      Presto.start_link(
        url: "http://some.url",
        user: "testing",
        table_schema: [{"name", "varchar"}],
        table: "table1"
      )

    assert {:error, "failed to query"} == Presto.write(pid, [{"bob"}])
  end

end

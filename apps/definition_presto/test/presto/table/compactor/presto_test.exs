defmodule Presto.Table.Compactor.PrestoTest do
  use ExUnit.Case
  use Placebo
  require Temp.Env

  Temp.Env.modify([
    %{
      app: :definition_presto,
      key: Presto.Table.Compactor.Presto,
      set: [
        catalog: "hive",
        user: "testing"
      ]
    }
  ])

  setup do
    destination =
      Presto.Table.new!(
        url: "http://localhost:8080",
        name: "table_a"
      )

    [destination: destination]
  end

  test "will return error if prestige returns an error", %{destination: destination} do
    allow(Prestige.execute(any(), any()), return: {:error, "failure"})

    assert {:error, "failure"} == Presto.Table.compact(destination)
  end

  test "will return error tuple if number of rows do not match", %{destination: destination} do
    allow(Prestige.execute(any(), any()), return: {:ok, :does_not_matter})
    allow(Prestige.execute(any(), starts_with("CREATE TABLE")), return: {:ok, %{rows: [[101]]}})

    allow(Prestige.execute(any(), "SELECT count(1) FROM table_a"), return: {:ok, %{rows: [[100]]}})

    expected_reason =
      "Failed 'table_a' compaction: New count (100) did not match original count (101)"

    assert {:error, expected_reason} == Presto.Table.compact(destination)
  end

  test "will delete the compact if an error occurs", %{destination: destination} do
    allow(Prestige.execute(any(), any()), return: {:error, "something bad happened"})

    assert {:error, "something bad happened"} == Presto.Table.compact(destination)

    assert_called(Prestige.execute(any(), "DROP TABLE IF EXISTS table_a_compact"))
  end
end

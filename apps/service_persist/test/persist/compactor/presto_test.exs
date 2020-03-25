defmodule Persist.Compactor.PrestoTest do
  use ExUnit.Case
  use Placebo
  require Temp.Env

  @prestige [
    url: "http://localhost:8080",
    user: "testing",
    catalog: "hive",
    schema: "default"
  ]

  Temp.Env.modify([
    %{
      app: :service_persist,
      key: Persist.Compactor.Presto,
      set: [
        prestige: @prestige
      ]
    }
  ])

  setup do
    persist =
      Load.Persist.new!(
        id: "persist-1",
        dataset_id: "ds1",
        subset_id: "sb1",
        source: Source.Fake.new(),
        destination: "table_a"
      )

    [persist: persist]
  end

  test "will return error if prestige returns an error", %{persist: persist} do
    allow Prestige.execute(any(), any()), return: {:error, "failure"}

    assert {:error, "failure"} == Persist.Compactor.Presto.compact(persist)
  end

  test "will return error tuple if number of rows do not match", %{persist: persist} do
    allow Prestige.execute(any(), any()), return: {:ok, :does_not_matter}
    allow Prestige.execute(any(), starts_with("CREATE TABLE")), return: {:ok, %{rows: [[101]]}}
    allow Prestige.execute(any(), "SELECT count(1) FROM table_a"), return: {:ok, %{rows: [[100]]}}

    expected_reason =
      "Failed 'table_a' compaction: New count (100) did not match original count (101)"

    assert {:error, expected_reason} == Persist.Compactor.Presto.compact(persist)
  end

  test "will delete the compact if an error occurs", %{persist: persist} do
    allow Prestige.execute(any(), any()), return: {:error, "something bad happened"}

    assert {:error, "something bad happened"} == Persist.Compactor.Presto.compact(persist)

    assert_called Prestige.execute(any(), "DROP TABLE IF EXISTS table_a_compact")
  end
end

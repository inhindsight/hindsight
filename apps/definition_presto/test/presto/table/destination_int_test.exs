defmodule Presto.Table.DestinationIntTest do
  use ExUnit.Case
  use Divo
  require Temp.Env
  import AssertAsync

  @moduletag integration: true, divo: true

  Temp.Env.modify([
    %{
      app: :definition_presto,
      key: Presto.Table.Destination,
      set: [
        user: "testing",
        catalog: "hive",
        staged_batches_count: 1
      ]
    },
    %{
      app: :definition_presto,
      key: Presto.Table.DataStorage.S3,
      set: [
        s3_bucket: "kdp-cloud-storage",
        s3_path: "hive-s3"
      ]
    }
  ])

  setup do
    Application.ensure_all_started(:hackney)
    Process.flag(:trap_exit, true)

    dictionary =
      Dictionary.from_list([
        Dictionary.Type.String.new!(name: "name"),
        Dictionary.Type.Integer.new!(name: "age"),
        Dictionary.Type.Date.new!(name: "birthdate", format: "%Y")
      ])

    destination =
      Presto.Table.new!(
        url: "http://localhost:8080",
        name: "table1"
      )

    context =
      Destination.Context.new!(
        dictionary: dictionary,
        app_name: "testing",
        dataset_id: "ds1",
        subset_id: "default"
      )

    session =
      Prestige.new_session(
        url: "http://localhost:8080",
        catalog: "hive",
        schema: "default",
        user: "testing"
      )

    {:ok, destination} = Destination.start_link(destination, context)
    on_exit(fn -> assert_down(destination.pid) end)

    [dictionary: dictionary, destination: destination, session: session]
  end

  @tag timeout: :infinity
  test "creates tables in presto correctly", %{destination: destination, session: session} do
    assert_async sleep: 1_000 do
      assert {:ok, result} = Prestige.execute(session, "DESCRIBE #{destination.name}")
      result = Prestige.Result.as_maps(result)

      assert result == [
               %{"Column" => "name", "Type" => "varchar", "Comment" => "", "Extra" => ""},
               %{"Column" => "age", "Type" => "bigint", "Comment" => "", "Extra" => ""},
               %{"Column" => "birthdate", "Type" => "date", "Comment" => "", "Extra" => ""}
             ]
    end

    assert_async sleep: 1_000 do
      assert {:ok, result} = Prestige.execute(session, "DESCRIBE #{destination.name}__staging")
      result = Prestige.Result.as_maps(result)

      assert result == [
               %{"Column" => "name", "Type" => "varchar", "Comment" => "", "Extra" => ""},
               %{"Column" => "age", "Type" => "bigint", "Comment" => "", "Extra" => ""},
               %{"Column" => "birthdate", "Type" => "date", "Comment" => "", "Extra" => ""}
             ]
    end
  end

  test "writes to table", %{session: session, destination: destination} do
    data = [
      %{"name" => "fred", "age" => 87, "birthdate" => "1956-01-01"},
      %{"name" => "joey", "age" => 12, "birthdate" => "1987-12-12"}
    ]

    Destination.write(destination, data)

    assert_async sleep: 1_000, max_tries: 30 do
      result =
        Prestige.query!(session, "select * from #{destination.name}")
        |> Prestige.Result.as_maps()

      assert result == data
    end
  end

  test "deletes both tables", %{session: session, destination: destination} do
    assert_async sleep: 1_000 do
      assert {:ok, _} = Prestige.execute(session, "DESCRIBE #{destination.name}")
    end

    Destination.delete(destination)

    assert_async sleep: 1_000 do
      assert {:error, _} = Prestige.execute(session, "DESCRIBE #{destination.name}")
    end
  end

  defp assert_down(pid, reason \\ :normal) do
    ref = Process.monitor(pid)
    Process.exit(pid, reason)
    assert_receive {:DOWN, ^ref, _, _, _}, 2_000
  end
end

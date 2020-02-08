defmodule Persist.Writer.DirectUploadIntTest do
  use ExUnit.Case
  use Divo
  require Temp.Env
  import AssertAsync

  @moduletag integration: true, divo: true

  Temp.Env.modify([
    %{
      app: :service_persist,
      key: Persist.TableCreator.Presto,
      set: [
        url: "http://localhost:8080",
        user: "testing",
        catalog: "hive",
        schema: "default"
      ]
    },
    %{
      app: :service_persist,
      key: Persist.Uploader.S3,
      set: [
        s3_bucket: "kdp-cloud-storage",
        s3_path: "hive-s3"
      ]
    }
  ])

  setup do
    Process.flag(:trap_exit, true)

    dictionary =
      Dictionary.from_list([
        Dictionary.Type.String.new!(name: "name"),
        Dictionary.Type.Integer.new!(name: "age"),
        Dictionary.Type.Date.new!(name: "birthdate", format: "%Y")
      ])

    load =
      Load.Persist.new!(
        id: "persist-1",
        dataset_id: "ds1",
        subset_id: "default",
        source: "topic-1",
        destination: "table1"
      )

    session =
      Prestige.new_session(
        url: "http://localhost:8080",
        catalog: "hive",
        schema: "default",
        user: "testing"
      )

    {:ok, writer} = Persist.Writer.DirectUpload.start_link(dictionary: dictionary, load: load)
    on_exit(fn -> assert_down(writer) end)

    [dictionary: dictionary, writer: writer, load: load, session: session]
  end

  test "creates table in presto correctly", %{load: load, session: session} do
    result =
      Prestige.execute!(session, "DESCRIBE #{load.destination}")
      |> Prestige.Result.as_maps()

    assert result == [
             %{"Column" => "name", "Type" => "varchar", "Comment" => "", "Extra" => ""},
             %{"Column" => "age", "Type" => "bigint", "Comment" => "", "Extra" => ""},
             %{"Column" => "birthdate", "Type" => "date", "Comment" => "", "Extra" => ""}
           ]
  end

  test "writes to table", %{writer: writer, session: session, load: load} do
    data = [
      %{"name" => "fred", "age" => 87, "birthdate" => "1956-01-01"},
      %{"name" => "joey", "age" => 12, "birthdate" => "1987-12-12"}
    ]

    Persist.Writer.DirectUpload.write(writer, data)

    assert_async sleep: 1_000, max_tries: 20 do
      result =
        Prestige.query!(session, "select * from #{load.destination}")
        |> Prestige.Result.as_maps()

      assert result == data
    end
  end

  defp assert_down(pid, reason \\ :normal) do
    ref = Process.monitor(pid)
    Process.exit(pid, reason)
    assert_receive {:DOWN, ^ref, _, _, _}
  end
end

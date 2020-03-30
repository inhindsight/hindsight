defmodule Persist.WriterIntTest do
  use ExUnit.Case
  use Divo
  require Temp.Env

  @moduletag integration: true, divo: true

  Temp.Env.modify([
    %{
      app: :service_persist,
      key: Persist.Writer,
      set: [
        url: "http://localhost:8080",
        user: "testing",
        catalog: "hive",
        schema: "default"
      ]
    }
  ])

  setup do
    Application.ensure_all_started(:hackney)

    :ok
  end

  @tag timeout: :infinity
  test "can write data to presto" do
    dictionary =
      Dictionary.from_list([
        Dictionary.Type.String.new!(name: "name"),
        Dictionary.Type.Integer.new!(name: "age"),
        Dictionary.Type.Date.new!(name: "birthdate", format: "%0m/%0d/%Y"),
        Dictionary.Type.Timestamp.new!(name: "arrival_time", format: "%0m/%0d/%Y %0H:%0M:%0S"),
        Dictionary.Type.Longitude.new!(name: "longitude"),
        Dictionary.Type.Latitude.new!(name: "latitude"),
        Dictionary.Type.Map.new!(
          name: "spouse",
          dictionary: [
            Dictionary.Type.String.new!(name: "name"),
            Dictionary.Type.Integer.new!(name: "age")
          ]
        ),
        Dictionary.Type.List.new!(
          name: "colors",
          item_type: Dictionary.Type.String.new!(name: "in_list")
        ),
        Dictionary.Type.List.new!(
          name: "friends",
          item_type:
            Dictionary.Type.Map.new!(
              name: "in_list",
              dictionary: [
                Dictionary.Type.String.new!(name: "name"),
                Dictionary.Type.Integer.new!(name: "age")
              ]
            )
        )
      ])

    message = %{
      "name" => "johnny",
      "birthdate" => "1999-02-23",
      "arrival_time" => "2020-01-02T05:12:24",
      "age" => 21,
      "longitude" => 150.0102687,
      "latitude" => 76.1234567,
      "spouse" => %{
        "name" => "shirley",
        "age" => 22
      },
      "colors" => ["red", "blue"],
      "friends" => [
        %{"name" => "bob", "age" => 24},
        %{"name" => "fred", "age" => 31}
      ]
    }

    expected = Map.put(message, "arrival_time", "2020-01-02 05:12:24.000")

    persist =
      Load.Persist.new!(
        id: "load-persist-1",
        dataset_id: "ds1",
        subset_id: "testing",
        source: Source.Fake.new!(),
        destination: "table2",
        schema: []
      )

    assert {:ok, pid} = Persist.Writer.start_link(load: persist, dictionary: dictionary)
    assert :ok = Persist.Writer.write(pid, [message], dictionary: dictionary)

    session =
      Prestige.new_session(
        url: "http://localhost:8080",
        user: "testing",
        catalog: "hive",
        schema: "default"
      )

    result =
      Prestige.query!(session, "SELECT * FROM table2")
      |> Prestige.Result.as_maps()

    assert [expected] == result
  end
end

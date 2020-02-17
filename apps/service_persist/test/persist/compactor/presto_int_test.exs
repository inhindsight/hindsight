defmodule Persist.Compactor.PrestoIntTest do
  use ExUnit.Case
  use Divo
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

  @moduletag integration: true, divo: true

  test "should compact a table in presto" do
    persist =
      Load.Persist.new!(
        id: "persist-1",
        dataset_id: "ds1",
        subset_id: "sb1",
        source: "topic-a",
        destination: "table_temp_table_167"
      )

    session = Prestige.new_session(@prestige)
    {:ok, _} = Prestige.execute(session, "CREATE TABLE table_a(name varchar, age integer)")

    1..10
    |> Enum.each(fn _ ->
      {:ok, _} =
        Prestige.execute(session, "INSERT INTO table_a(name, age) values(#{generate_row()})")
    end)

    Prestige.execute!(session, "select * from table_a")
    |> Prestige.Result.as_maps()

    assert 10 <= number_of_s3_files(persist.destination)

    assert :ok == Persist.Compactor.Presto.compact(persist)

    assert 1 == number_of_s3_files(persist.destination)
  end

  defp number_of_s3_files(table) do
    ExAws.S3.list_objects("kdp-cloud-storage")
    |> ExAws.request!()
    |> (fn response -> response.body.contents end).()
    |> Enum.map(&Map.get(&1, :key))
    |> Enum.filter(&String.starts_with?(&1, "hive-s3/#{table}/"))
    |> length()
  end

  defp generate_row() do
    "'#{random_string(10)}', #{:crypto.rand_uniform(0, 100)}"
  end

  defp random_string(length) do
    :crypto.strong_rand_bytes(length) |> Base.url_encode64() |> binary_part(0, length)
  end
end

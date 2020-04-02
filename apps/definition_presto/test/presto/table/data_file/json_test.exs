defmodule Presto.Table.DataFile.JsonTest do
  use ExUnit.Case

  test "should open write a close a json file" do
    dictionary = [
      Dictionary.Type.Integer.new!(name: "id"),
      Dictionary.Type.String.new!(name: "name"),
      Dictionary.Type.Timestamp.new!(name: "ts", format: "%Y")
    ]

    data = [
      %{"id" => 1, "name" => "John", "ts" => "2012-01-01T01:01:01"},
      %{"id" => 2, "name" => "Joe", "ts" => "2012-01-01T01:01:02"},
      %{"id" => 3, "name" => "Sean", "ts" => "2012-01-01T01:01:03"}
    ]

    {:ok, json} = Presto.Table.DataFile.Json.open("table_a", dictionary)
    Presto.Table.DataFile.Json.write(json, Enum.take(data, 2))
    Presto.Table.DataFile.Json.write(json, Enum.drop(data, 2))

    path = Presto.Table.DataFile.Json.close(json)
    on_exit(fn -> File.rm(path) end)

    result =
      File.read!(path)
      |> :zlib.gunzip()
      |> String.split("\n")
      |> Enum.reject(fn x -> x == "" end)
      |> Enum.map(&Jason.decode!/1)

    expected =
      Enum.map(
        data,
        &Map.update!(&1, "ts", fn x ->
          NaiveDateTime.from_iso8601!(x)
          |> Timex.format!("%Y-%m-%d %H:%M:%S.%-f", :strftime)
        end)
      )

    assert result == expected
  end
end

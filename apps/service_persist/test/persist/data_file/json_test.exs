defmodule Persist.DataFile.JsonTest do
  use ExUnit.Case

  test "should open write a close a json file" do
    data = [
      %{"id" => 1, "name" => "John"},
      %{"id" => 2, "name" => "Joe"},
      %{"id" => 3, "name" => "Sean"}
    ]

    {:ok, json} = Persist.DataFile.Json.open("table_a", [])
    Persist.DataFile.Json.write(json, Enum.take(data, 2))
    Persist.DataFile.Json.write(json, Enum.drop(data, 2))

    path = Persist.DataFile.Json.close(json)
    on_exit(fn -> File.rm(path) end)

    result =
      File.read!(path)
      |> :zlib.gunzip()
      |> String.split("\n")
      |> Enum.reject(fn x -> x == "" end)
      |> Enum.map(&Jason.decode!/1)

    assert result == data
  end
end

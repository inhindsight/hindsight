defmodule Presto.Table.Json.TranslatorTest do
  use ExUnit.Case
  import Checkov

  data_test "translate #{input} to json" do
    assert {:ok, output} == Presto.Table.Json.Translator.translate(type, input)

    where([
      [:input, :output, :type],
      ["a string", "a string", Dictionary.Type.String.new!(name: "a name")],
      [10, 10, Dictionary.Type.Integer.new!(name: "a integer")],
      [
        "2020-01-01T01:27:41",
        "2020-01-01 01:27:41.0",
        Dictionary.Type.Timestamp.new!(name: "a timestamp", format: "%Y")
      ],
      [
        "2020-01-01T01:27:41Z",
        "2020-01-01 01:27:41.0",
        Dictionary.Type.Timestamp.new!(name: "a timestamp", format: "%Y")
      ]
    ])
  end

  test "translates values in simple list" do
    list =
      Dictionary.Type.List.new!(
        name: "list",
        item_type: Dictionary.Type.Timestamp.new!(name: "in_list", format: "%Y")
      )

    assert {:ok, ["2020-01-01 01:27:41.0"]} ==
             Presto.Table.Json.Translator.translate(list, ["2020-01-01T01:27:41Z"])
  end

  test "translates values in a map" do
    map =
      Dictionary.Type.Map.new!(
        name: "map",
        dictionary: [
          Dictionary.Type.String.new!(name: "string"),
          Dictionary.Type.Timestamp.new!(name: "timestamp", format: "%Y")
        ]
      )

    input = %{
      "string" => "some value",
      "timestamp" => "2020-01-01T01:27:41Z"
    }

    expected = %{
      "string" => "some value",
      "timestamp" => "2020-01-01 01:27:41.0"
    }

    assert {:ok, expected} == Presto.Table.Json.Translator.translate(map, input)
  end
end

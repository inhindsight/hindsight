defmodule Avro.TranslatorTest do
  use ExUnit.Case
  import Checkov

  data_test "primitive types" do
    avro_field = Avro.Translator.field(type)
    {:ok, avro_value} = Avro.Translator.value(type, value)
    schema = :avro_record.type("person", [avro_field])

    encoder = :avro.make_simple_encoder(schema, [])
    decoder = :avro.make_simple_decoder(schema, [])

    input = %{type.name => avro_value}

    result =
      input
      |> encoder.()
      |> decoder.()
      |> Map.new()

    assert Map.get(result, type.name) == expected

    where [
      [:type, :value, :expected],
      [Dictionary.Type.String.new!(name: "name"), "joe", "joe"],
      [Dictionary.Type.Integer.new!(name: "age"), 21, 21],
      [Dictionary.Type.Float.new!(name: "height"), 6.05, 6.05],
      [Dictionary.Type.Boolean.new!(name: "active?"), true, true],
      [Dictionary.Type.Date.new!(name: "birthdate", format: "%Y"), "1978-05-27", 3068],
      [
        Dictionary.Type.Timestamp.new!(name: "timestamp", format: "%Y"),
        "1977-05-27T00:00:00Z",
        233_539_200_000
      ],
      [Dictionary.Type.Latitude.new!(name: "lat"), 85.65, 85.65],
      [Dictionary.Type.Longitude.new!(name: "long"), 100.65, 100.65],
      [
        Dictionary.Type.Wkt.Point.new!(name: "point"),
        "POINT(100.65 85.65)",
        "POINT(100.65 85.65)"
      ]
    ]
  end

  test "converts map" do
    type =
      Dictionary.Type.Map.new!(
        name: "spouse",
        dictionary: [
          Dictionary.Type.String.new!(name: "name"),
          Dictionary.Type.Integer.new!(name: "age"),
          Dictionary.Type.Date.new!(name: "birthdate", format: "%Y")
        ]
      )

    avro_field = Avro.Translator.field(type)
    schema = :avro_record.type("person", [avro_field])

    encoder = :avro.make_simple_encoder(schema, [])
    decoder = :avro.make_simple_decoder(schema, [])

    {:ok, input} =
      Avro.Translator.value(type, %{"name" => "becky", "age" => 21, "birthdate" => "1978-05-27"})

    result =
      %{"spouse" => input}
      |> encoder.()
      |> decoder.()
      |> Map.new()
      |> Map.update!("spouse", &Map.new/1)

    assert result == %{"spouse" => input}
  end

  test "converts simple list" do
    type =
      Dictionary.Type.List.new!(
        name: "colors",
        item_type: Dictionary.Type.Date.new!(name: "in_list", format: "%Y")
      )

    avro_field = Avro.Translator.field(type)
    schema = :avro_record.type("person", [avro_field])

    encoder = :avro.make_simple_encoder(schema, [])
    decoder = :avro.make_simple_decoder(schema, [])

    {:ok, input} = Avro.Translator.value(type, ["1982-01-05", "1999-11-14"])

    result =
      %{"colors" => input}
      |> encoder.()
      |> decoder.()
      |> Map.new()
      |> Map.get("colors")

    assert result == input
  end

  test "converts list of maps" do
    type =
      Dictionary.Type.List.new!(
        name: "friends",
        item_type:
          Dictionary.Type.Map.new!(
            name: "in_list",
            dictionary: [
              Dictionary.Type.String.new!(name: "name"),
              Dictionary.Type.Integer.new!(name: "age"),
              Dictionary.Type.Date.new!(name: "birthdate", format: "%Y"),
              Dictionary.Type.Map.new!(
                name: "position",
                dictionary: [
                  Dictionary.Type.Integer.new!(name: "x"),
                  Dictionary.Type.Integer.new!(name: "y")
                ]
              )
            ]
          )
      )

    avro_field = Avro.Translator.field(type)
    schema = :avro_record.type("person", [avro_field])

    encoder = :avro.make_simple_encoder(schema, [])
    decoder = :avro.make_simple_decoder(schema, [])

    {:ok, input} =
      Avro.Translator.value(type, [
        %{
          "name" => "bob",
          "age" => 21,
          "birthdate" => "1956-12-01",
          "position" => %{"x" => 3, "y" => 4}
        },
        %{
          "name" => "fred",
          "age" => 22,
          "birthdate" => "1975-01-01",
          "position" => %{"x" => 1, "y" => 2}
        }
      ])

    result =
      %{"friends" => input}
      |> encoder.()
      |> decoder.()
      |> Map.new()
      |> Map.get("friends")
      |> Enum.map(&nested_map/1)

    assert result == input
  end

  defp nested_map(list) do
    Enum.map(list, fn
      {"position", vals} -> {"position", Enum.into(vals, %{})}
      kv -> kv
    end)
    |> Map.new()
  end
end

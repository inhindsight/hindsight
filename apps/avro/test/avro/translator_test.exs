defmodule Avro.TranslatorTest do
  use ExUnit.Case
  import Checkov

  data_test "primitive types" do
    avro_type = Avro.Translator.translate_type(type)
    schema = :avro_record.type("person", [avro_type])

    encoder = :avro.make_simple_encoder(schema, [])
    decoder = :avro.make_simple_decoder(schema, [])

    input = %{type.name => value}

    result =
      input
      |> encoder.()
      |> decoder.()
      |> Map.new()

    assert result == input

    where [
      [:type, :value],
      [Dictionary.Type.String.new!(name: "name"), "joe"],
      [Dictionary.Type.Integer.new!(name: "age"), 21],
      [Dictionary.Type.Float.new!(name: "height"), 6.05],
      [Dictionary.Type.Boolean.new!(name: "active?"), true]
    ]
  end

  test "converts map" do
    type =
      Dictionary.Type.Map.new!(
        name: "spouse",
        dictionary: [
          Dictionary.Type.String.new!(name: "name"),
          Dictionary.Type.Integer.new!(name: "age")
        ]
      )

    avro_type = Avro.Translator.translate_type(type)
    schema = :avro_record.type("person", [avro_type])

    encoder = :avro.make_simple_encoder(schema, [])
    decoder = :avro.make_simple_decoder(schema, [])

    input = %{"spouse" => %{"name" => "becky", "age" => 21}}

    result =
      input
      |> encoder.()
      |> decoder.()
      |> Map.new()
      |> Map.update!("spouse", &Map.new/1)

    assert result == input
  end
end

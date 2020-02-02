defmodule AvroTest do
  use ExUnit.Case

  test "will create a new schema from a dictionary" do
    dictionary =
      Dictionary.from_list([
        Dictionary.Type.String.new!(name: "name"),
        Dictionary.Type.Integer.new!(name: "age")
      ])

    assert {:ok, avro} = Avro.open("people", dictionary)

    assert {:ok, 209,} =
             Avro.write(avro, [
               %{"name" => "joe", "age" => 21},
               %{"name" => "bob", "age" => 23}
             ])

    file = Avro.close(avro)

    assert {header, schema, data} = :avro_ocf.decode_file(file)

    assert Enum.map(data, &Map.new/1) == [
             %{"name" => "joe", "age" => 21},
             %{"name" => "bob", "age" => 23}
           ]
  end
end

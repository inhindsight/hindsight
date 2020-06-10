defmodule Decoder.JsonTest do
  use ExUnit.Case

  test "serialization" do
    struct = Decoder.Json.new!([])

    serialized = JsonSerde.serialize!(struct)

    assert JsonSerde.deserialize!(serialized) == struct
  end

  describe "Decoder" do
    test "decodes json array message to json" do
      input = [
        ~s([{\"name\": \"Kyle\", \"age\": 2},{\"name\": \"Joe\", \"age\": 21},{\"name\": \"Bobby\",\"age\": 62}])
      ]

      output = Decoder.decode(Decoder.Json.new!([]), input)

      assert output == [
               %{"name" => "Kyle", "age" => 2},
               %{"name" => "Joe", "age" => 21},
               %{"name" => "Bobby", "age" => 62}
             ]
    end

    test "decodes a non-list message to json" do
      input = [
        ~s({"name": "Jay", "age": 42})
      ]

      output = Decoder.decode(Decoder.Json.new!([]), input)

      assert output == [%{"name" => "Jay", "age" => 42}]
    end
  end
end

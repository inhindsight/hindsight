defmodule Decoder.JsonTest do
  use ExUnit.Case

  test "can be decoded back into struct" do
    struct = Decoder.Json.new!([])
    json = Jason.encode!(struct)

    assert {:ok, struct} == Jason.decode!(json) |> Decoder.Json.new()
  end

  test "brook serializer can serialize and deserialize" do
    struct = Decoder.Json.new!([])

    assert {:ok, struct} =
             Brook.Serializer.serialize(struct) |> elem(1) |> Brook.Deserializer.deserialize()
  end

  describe "Decoder" do
    test "decodes stream to json" do
      input = [
        [~s([), ~s({\"name\": \"Kyle\", \"age\": 2},{\"name\": \"Joe\")],
        [~s(, \"age\": 21},{\"name\": \"Bobby\",\"age\": 62}), ~s(])]
      ]

      output = Decoder.decode(Decoder.Json.new!([]), input)

      assert Enum.to_list(output) == [
               [
                 %{"name" => "Kyle", "age" => 2},
                 %{"name" => "Joe", "age" => 21},
                 %{"name" => "Bobby", "age" => 62}
               ]
             ]
    end

    test "decodes a non-list stream to json" do
      input = [
        [
          ~s({"name": "Jay",),
          ~s("age": 42})
        ]
      ]

      output = Decoder.decode(Decoder.Json.new!([]), input)

      assert Enum.to_list(output) == [[%{"name" => "Jay", "age" => 42}]]
    end
  end
end

defmodule Decoder.JsonLinesTest do
  use ExUnit.Case

  test "can be decoded back into struct" do
    struct = Decoder.JsonLines.new!([])
    json = Jason.encode!(struct)

    assert {:ok, struct} == Jason.decode!(json) |> Decoder.JsonLines.new()
  end

  test "brook serializer can serialize and deserialize" do
    struct = Decoder.JsonLines.new!([])

    assert {:ok, struct} =
             Brook.Serializer.serialize(struct) |> elem(1) |> Brook.Deserializer.deserialize()
  end

  describe "Decoder" do
    test "decodes json lines file as a stream" do
      input = [
        [json(%{"name" => "john", "age" => 21}), json(%{"name" => "Fred", "age" => 34})],
        [json(%{"name" => "george", "age" => 36})]
      ]

      output = Decoder.decode(Decoder.JsonLines.new!([]), input)

      assert Enum.to_list(output) == [
               [%{"name" => "john", "age" => 21}, %{"name" => "Fred", "age" => 34}],
               [%{"name" => "george", "age" => 36}]
             ]
    end
  end

  defp json(map), do: Jason.encode!(map)
end

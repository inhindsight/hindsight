defmodule Decoder.JsonLinesTest do
  use ExUnit.Case

  test "serialization" do
    struct = Decoder.JsonLines.new!([])

    serialized = JsonSerde.serialize!(struct)

    assert JsonSerde.deserialize!(serialized) == struct
  end

  describe "Decoder" do
    test "decodes json lines file as a batch of messages" do
      input = [
        json(%{"name" => "john", "age" => 21}),
        json(%{"name" => "Fred", "age" => 34}),
        json(%{"name" => "george", "age" => 36})
      ]

      output = Decoder.decode(Decoder.JsonLines.new!([]), input)

      assert output ==
               [
                 %{"name" => "john", "age" => 21},
                 %{"name" => "Fred", "age" => 34},
                 %{"name" => "george", "age" => 36}
               ]
    end
  end

  defp json(map), do: Jason.encode!(map)
end

defmodule Dictionary.Type.Wkt.PointTest do
  use ExUnit.Case
  import Checkov

  test "can be encoded to json" do
    expected = %{
      "version" => 1,
      "name" => "name",
      "description" => "description",
      "type" => "wkt_point"
    }

    assert expected ==
             Jason.encode!(%Dictionary.Type.Wkt.Point{name: "name", description: "description"})
             |> Jason.decode!()
  end

  test "can be decoded back into struct" do
    string = Dictionary.Type.Wkt.Point.new!(name: "name", description: "description")
    json = Jason.encode!(string)

    assert {:ok, string} == Jason.decode!(json) |> Dictionary.Type.Wkt.Point.new()
  end

  test "brook serializer can serialize and deserialize" do
    string = Dictionary.Type.Wkt.Point.new!(name: "name", description: "description")

    assert {:ok, string} =
             Brook.Serializer.serialize(string) |> elem(1) |> Brook.Deserializer.deserialize()
  end

  data_test "validates strings - #{inspect(value)} --> #{inspect(result)}" do
    assert result == Dictionary.Type.Normalizer.normalize(%Dictionary.Type.Wkt.Point{}, value)

    where [
      [:value, :result],
      ["string", {:ok, "string"}],
      ["  string  ", {:ok, "string"}],
      [123, {:ok, "123"}],
      [nil, {:ok, ""}],
      [{:one, :two}, {:error, :invalid_string}]
    ]
  end
end

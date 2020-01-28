defmodule Dictionary.Type.LongitudeTest do
  use ExUnit.Case
  import Checkov

  describe "new/1" do
    data_test "validates #{inspect(field)} against bad input" do
      assert {:error, [%{input: value, path: [field]} | _]} =
               put_in(%{}, [field], value)
               |> Dictionary.Type.Longitude.new()

      where [
        [:field, :value],
        [:version, "1"],
        [:name, ""],
        [:name, nil],
        [:description, nil]
      ]
    end
  end

  test "can be encoded to json" do
    expected = %{
      "version" => 1,
      "name" => "name",
      "description" => "description",
      "type" => "longitude"
    }

    assert expected ==
             Jason.encode!(%Dictionary.Type.Longitude{name: "name", description: "description"})
             |> Jason.decode!()
  end

  test "can be decoded back into struct" do
    longitude = Dictionary.Type.Longitude.new!(name: "name", description: "description")
    json = Jason.encode!(longitude)

    assert {:ok, longitude} == Jason.decode!(json) |> Dictionary.Type.Longitude.new()
  end

  test "brook serializer can serialize and deserialize" do
    longitude = Dictionary.Type.Longitude.new!(name: "name", description: "description")

    assert {:ok, string} =
             Brook.Serializer.serialize(longitude) |> elem(1) |> Brook.Deserializer.deserialize()
  end

  data_test "validates longitudes - #{inspect(value)} --> #{inspect(result)}" do
    assert result == Dictionary.Type.Normalizer.normalize(%Dictionary.Type.Longitude{}, value)

    where [
      [:value, :result],
      ["180", {:ok, 180.0}],
      ["180.0", {:ok, 180.0}],
      [180, {:ok, 180.0}],
      [180.0, {:ok, 180.0}],
      ["-180.0", {:ok, -180.0}],
      ["-180", {:ok, -180.0}],
      [-180, {:ok, -180.0}],
      [-180.0, {:ok, -180.0}],
      [181, {:error, :invalid_longitude}],
      [180.000001, {:error, :invalid_longitude}],
      [179.9999999, {:ok, 179.9999999}],
      [-181, {:error, :invalid_longitude}],
      [-181.000001, {:error, :invalid_longitude}],
      [-179.9999999, {:ok, -179.9999999}],
      ["seventy-six", {:error, :invalid_longitude}]
    ]
  end
end

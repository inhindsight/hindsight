defmodule Dictionary.Type.LatitudeTest do
  use ExUnit.Case
  import Checkov

  describe "new/1" do
    data_test "validates #{inspect(field)} against bad input" do
      assert {:error, [%{input: value, path: [field]} | _]} =
               put_in(%{}, [field], value)
               |> Dictionary.Type.Latitude.new()

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
      "type" => "latitude"
    }

    assert expected ==
             Jason.encode!(%Dictionary.Type.Latitude{name: "name", description: "description"})
             |> Jason.decode!()
  end

  test "can be decoded back into struct" do
    latitude = Dictionary.Type.Latitude.new!(name: "name", description: "description")
    json = Jason.encode!(latitude)

    assert {:ok, latitude} == Jason.decode!(json) |> Dictionary.Type.Latitude.new()
  end

  test "brook serializer can serialize and deserialize" do
    latitude = Dictionary.Type.Latitude.new!(name: "name", description: "description")

    assert {:ok, string} =
             Brook.Serializer.serialize(latitude) |> elem(1) |> Brook.Deserializer.deserialize()
  end

  data_test "validates latitudes - #{inspect(value)} --> #{inspect(result)}" do
    assert result == Dictionary.Type.Normalizer.normalize(%Dictionary.Type.Latitude{}, value)

    where [
      [:value, :result],
      ["90", {:ok, 90.0}],
      ["90.0", {:ok, 90.0}],
      [90, {:ok, 90.0}],
      [90.0, {:ok, 90.0}],
      ["-90.0", {:ok, -90.0}],
      ["-90", {:ok, -90.0}],
      [-90, {:ok, -90.0}],
      [-90.0, {:ok, -90.0}],
      [91, {:error, :invalid_latitude}],
      [90.000001, {:error, :invalid_latitude}],
      [89.9999999, {:ok, 89.9999999}],
      [-91, {:error, :invalid_latitude}],
      [-91.000001, {:error, :invalid_latitude}],
      [-89.9999999, {:ok, -89.9999999}],
      ["seventy-six", {:error, :invalid_latitude}],
      [nil, {:ok, nil}]
    ]
  end
end

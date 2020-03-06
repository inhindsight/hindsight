defmodule Dictionary.Type.FloatTest do
  use ExUnit.Case
  import Checkov

  describe "new/1" do
    data_test "validates #{inspect(field)} against bad input" do
      assert {:error, [%{input: value, path: [field]} | _]} =
               put_in(%{}, [field], value)
               |> Dictionary.Type.Float.new()

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
      "version" => 1.0,
      "name" => "name",
      "description" => "precise number",
      "type" => "float"
    }

    assert expected ==
             Jason.encode!(%Dictionary.Type.Float{name: "name", description: "precise number"})
             |> Jason.decode!()
  end

  test "can be decoded back to a struct" do
    float = Dictionary.Type.Float.new!(name: "name", description: "precise number")
    json = Jason.encode!(float)

    assert {:ok, float} == Jason.decode!(json) |> Dictionary.Type.Float.new()
  end

  test "brook serializer can serialize and deserialize" do
    float = Dictionary.Type.Float.new!(name: "name", description: "precise number")

    assert {:ok, float} =
             Brook.Serializer.serialize(float) |> elem(1) |> Brook.Deserializer.deserialize()
  end

  data_test "validates floats -- #{inspect(value)} --> #{inspect(result)}" do
    assert result == Dictionary.Type.Normalizer.normalize(%Dictionary.Type.Float{}, value)

    where [
      [:value, :result],
      [3.14, {:ok, 3.14}],
      ["25.1", {:ok, 25.1}],
      ["quarter", {:error, :invalid_float}],
      [nil, {:ok, nil}],
      ["", {:ok, nil}]
    ]
  end
end

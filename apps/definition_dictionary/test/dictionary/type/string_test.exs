defmodule Dictionary.Type.StringTest do
  use ExUnit.Case
  import Checkov

  describe "new/1" do
    data_test "validates #{inspect(field)} against bad input" do
      assert {:error, [%{input: value, path: [field]} | _]} =
               put_in(%{}, [field], value)
               |> Dictionary.Type.String.new()

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
      "type" => "string"
    }

    assert expected ==
             Jason.encode!(%Dictionary.Type.String{name: "name", description: "description"})
             |> Jason.decode!()
  end

  test "can be decoded back into struct" do
    string = Dictionary.Type.String.new!(name: "name", description: "description")
    json = Jason.encode!(string)

    assert {:ok, string} == Jason.decode!(json) |> Dictionary.Type.String.new()
  end

  test "brook serializer can serialize and deserialize" do
    string = Dictionary.Type.String.new!(name: "name", description: "description")

    assert {:ok, string} =
             Brook.Serializer.serialize(string) |> elem(1) |> Brook.Deserializer.deserialize()
  end

  data_test "validates strings - #{inspect(value)} --> #{inspect(result)}" do
    assert result == Dictionary.Type.Normalizer.normalize(%Dictionary.Type.String{}, value)

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

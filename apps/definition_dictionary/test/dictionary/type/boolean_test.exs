defmodule Dictionary.Type.BooleanTest do
  use ExUnit.Case
  import Checkov

  test "can be encoded to json" do
    expected = %{
      "version" => 1,
      "name" => "name",
      "description" => "do or do not",
      "type" => "boolean"
    }

    assert expected ==
             Jason.encode!(%Dictionary.Type.Boolean{name: "name", description: "do or do not"})
             |> Jason.decode!()
  end

  test "can be decoded back into struct" do
    boolean = Dictionary.Type.Boolean.new!(name: "name", description: "do or do not")
    json = Jason.encode!(boolean)

    assert {:ok, boolean} == Jason.decode!(json) |> Dictionary.Type.Boolean.new()
  end

  test "brook can serialize and deserialize" do
    boolean = Dictionary.Type.Boolean.new!(name: "name", description: "do or do not")

    assert {:ok, boolean} ==
             Brook.Serializer.serialize(boolean) |> elem(1) |> Brook.Deserializer.deserialize()
  end

  data_test "validates booleans -- #{inspect(value)} --> #{inspect(result)}" do
    assert result == Dictionary.Type.Normalizer.normalize(%Dictionary.Type.Boolean{}, value)

    where [
      [:value, :result],
      [true, {:ok, true}],
      ["false", {:ok, false}],
      ["sure", {:error, :invalid_boolean}],
      [nil, {:ok, nil}],
      ["", {:ok, nil}]
    ]
  end
end

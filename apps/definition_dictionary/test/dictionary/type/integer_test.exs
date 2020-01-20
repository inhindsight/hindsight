defmodule Dictionary.Type.IntegerTest do
  use ExUnit.Case
  import Checkov

  describe "new/1" do
    data_test "validates #{inspect(field)} against bad input" do
      assert {:error, [%{input: value, path: [field]} | _]} =
               put_in(%{}, [field], value)
               |> Dictionary.Type.Integer.new()

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
      "type" => "integer"
    }

    assert expected ==
             Jason.encode!(%Dictionary.Type.Integer{name: "name", description: "description"})
             |> Jason.decode!()
  end

  test "can be decoded back into struct" do
    integer = Dictionary.Type.Integer.new!(name: "name", description: "description")
    json = Jason.encode!(integer)

    assert {:ok, integer} == Jason.decode!(json) |> Dictionary.Type.Integer.new()
  end

  test "brook serializer can serialize and deserialize" do
    integer = Dictionary.Type.Integer.new!(name: "name", description: "description")

    assert {:ok, integer} == Brook.Serializer.serialize(integer) |> elem(1) |> Brook.Deserializer.deserialize()
  end

  data_test "validates integers -- #{inspect(value)} --> #{inspect(result)}" do
    assert result == Dictionary.Type.Normalizer.normalize(%Dictionary.Type.Integer{}, value)

    where [
      [:value, :result],
      [1, {:ok, 1}],
      ["123", {:ok, 123}],
      ["one", {:error, :invalid_integer}]
    ]
  end
end

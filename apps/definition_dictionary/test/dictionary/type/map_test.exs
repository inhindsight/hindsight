defmodule Dictionary.Type.MapTest do
  use ExUnit.Case
  import Checkov

  describe "new/1" do
    data_test "validates #{inspect(field)} against bad input" do
      assert {:error, [%{input: value, path: [field]} | _]} =
               put_in(%{}, [field], value)
               |> Dictionary.Type.Map.new()

      where [
        [:field, :value],
        [:version, "1"],
        [:name, ""],
        [:name, nil],
        [:description, nil],
        [:fields, nil],
        [:fields, "one"]
      ]
    end
  end

  test "can be encoded to json" do
    expected = %{
      "version" => 1,
      "name" => "name",
      "description" => "description",
      "type" => "map",
      "fields" => [
        %{"version" => 1, "name" => "name", "description" => "", "type" => "string"},
        %{"version" => 1, "name" => "age", "description" => "", "type" => "integer"}
      ]
    }

    map = %Dictionary.Type.Map{
      name: "name",
      description: "description",
      fields: [
        %Dictionary.Type.String{name: "name"},
        %Dictionary.Type.Integer{name: "age"}
      ]
    }

    assert expected == Jason.encode!(map) |> Jason.decode!()
  end

  test "can be decoded back into struct" do
    map =
      Dictionary.Type.Map.new!(
        name: "name",
        description: "description",
        fields: [
          Dictionary.Type.String.new!(name: "name"),
          Dictionary.Type.Integer.new!(name: "age")
        ]
      )

    json = Jason.encode!(map)

    assert {:ok, map} == Jason.decode!(json) |> Dictionary.Type.Map.new()
  end

  test "brook serializer can serialize and deserialize" do
    map =
      Dictionary.Type.Map.new!(
        name: "name",
        description: "description",
        fields: [
          Dictionary.Type.String.new!(name: "name"),
          Dictionary.Type.Integer.new!(name: "age")
        ]
      )

    assert {:ok, map} ==
             Brook.Serializer.serialize(map) |> elem(1) |> Brook.Deserializer.deserialize()
  end

  data_test "normalizes all fields inside map" do
    value = %{
      "name" => name,
      "age" => age
    }

    field = %Dictionary.Type.Map{
      name: "spouse",
      fields: [
        %Dictionary.Type.String{name: "name"},
        %Dictionary.Type.Integer{name: "age"}
      ]
    }

    assert result == Dictionary.Type.Normalizer.normalize(field, value)

    where [
      [:name, :age, :result],
      ["george", 21, {:ok, %{"name" => "george", "age" => 21}}],
      ["fred", "abc", {:error, %{"age" => :invalid_integer}}]
    ]
  end
end

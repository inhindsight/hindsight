defmodule Dictionary.Type.ListTest do
  use ExUnit.Case
  import Checkov

  describe "new/1" do
    data_test "validates #{inspect(field)} against bad input" do
      assert {:error, [%{input: value, path: [field]} | _]} =
               put_in(%{}, [field], value)
               |> Dictionary.Type.List.new()

      where [
        [:field, :value],
        [:version, "1"],
        [:name, ""],
        [:name, nil],
        [:description, nil],
        [:item_type, ""],
        [:item_type, nil],
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
      "type" => "list",
      "item_type" => "map",
      "fields" => [
        %{"version" => 1, "name" => "name", "description" => "", "type" => "string"},
        %{"version" => 1, "name" => "age", "description" => "", "type" => "integer"}
      ]
    }

    list = %Dictionary.Type.List{
      name: "name",
      description: "description",
      item_type: Dictionary.Type.Map,
      fields: [
        %Dictionary.Type.String{name: "name"},
        %Dictionary.Type.Integer{name: "age"}
      ]
    }

    assert expected == Jason.encode!(list) |> Jason.decode!()
  end

  test "can be decoded back into struct" do
    list =
      Dictionary.Type.List.new!(
        name: "name",
        description: "description",
        item_type: Dictionary.Type.Map,
        fields: [
          Dictionary.Type.String.new!(name: "name"),
          Dictionary.Type.Integer.new!(name: "age")
        ]
      )

    json = Jason.encode!(list)

    assert {:ok, list} == Jason.decode!(json) |> Dictionary.Type.List.new()
  end

  test "brook serializer can serialize and deserialize" do
    list =
      Dictionary.Type.List.new!(
        name: "name",
        description: "description",
        item_type: Dictionary.Type.Map,
        fields: [
          Dictionary.Type.String.new!(name: "name"),
          Dictionary.Type.Integer.new!(name: "age")
        ]
      )

    assert {:ok, list} ==
             Brook.Serializer.serialize(list) |> elem(1) |> Brook.Deserializer.deserialize()
  end

  data_test "normalizes data in maps according to field rules" do
    field = %Dictionary.Type.List{
      name: "friends",
      item_type: Dictionary.Type.Map,
      fields: [
        %Dictionary.Type.String{name: "name"},
        %Dictionary.Type.Integer{name: "age"}
      ]
    }

    value = [
      %{
        "name" => name,
        "age" => age
      }
    ]

    assert result == Dictionary.Type.Normalizer.normalize(field, value)

    where [
      [:name, :age, :result],
      ["holly", 27, {:ok, [%{"name" => "holly", "age" => 27}]}],
      [
        {:one},
        "abc",
        {:error, {:invalid_list, %{"name" => :invalid_string, "age" => :invalid_integer}}}
      ]
    ]
  end

  test "normalizes data in simple type" do
    field = %Dictionary.Type.List{
      item_type: Dictionary.Type.String
    }

    value = [
      "one",
      "  two  "
    ]

    assert {:ok, ["one", "two"]} == Dictionary.Type.Normalizer.normalize(field, value)
  end
end

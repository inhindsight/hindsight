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

  describe "Dictionary.Type.Decoder.decode/2" do
    data_test "validates #{inspect(field)} against bad input" do
      assert {:error, [%{input: value, path: [field]} | _]} =
               put_in(%{}, [field], value)
               |> decode()

      where [
        [:field, :value],
        ["version", "1"],
        ["name", ""],
        ["name", nil],
        ["description", nil],
        ["item_type", ""],
        ["item_type", nil],
        ["fields", nil],
        ["fields", "one"]
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
      item_type: "map",
      fields: [
        %Dictionary.Type.String{name: "name"},
        %Dictionary.Type.Integer{name: "age"}
      ]
    }

    assert expected == Jason.encode!(list) |> Jason.decode!()
  end

  test "can be decoded back into struct" do
    list = %{
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

    expected =
      {:ok,
       %Dictionary.Type.List{
         name: "name",
         description: "description",
         item_type: "map",
         fields: [
           %Dictionary.Type.String{name: "name"},
           %Dictionary.Type.Integer{name: "age"}
         ]
       }}

    assert expected == Dictionary.Type.Decoder.decode(struct(Dictionary.Type.List), list)
  end

  defp decode(map) do
    Dictionary.Type.Decoder.decode(struct(Dictionary.Type.List), map)
  end
end

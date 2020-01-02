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
    map = %{
      "version" => 1,
      "name" => "name",
      "description" => "description",
      "type" => "map",
      "fields" => [
        %{"version" => 1, "name" => "name", "description" => "", "type" => "string"},
        %{"version" => 1, "name" => "age", "description" => "", "type" => "integer"}
      ]
    }

    expected =
      {:ok,
       %Dictionary.Type.Map{
         name: "name",
         description: "description",
         fields: [
           %Dictionary.Type.String{name: "name"},
           %Dictionary.Type.Integer{name: "age"}
         ]
       }}

    assert expected == Dictionary.Type.Decoder.decode(struct(Dictionary.Type.Map), map)
  end

  defp decode(map) do
    Dictionary.Type.Decoder.decode(struct(Dictionary.Type.String), map)
  end
end

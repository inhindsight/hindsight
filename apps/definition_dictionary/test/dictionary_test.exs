defmodule DictionaryTest do
  use ExUnit.Case

  describe "encode/1" do
    test "encodes list of dictionary types to json" do
      dictionary = [
        %Dictionary.Type.String{name: "name"},
        %Dictionary.Type.Integer{name: "age"}
      ]

      expected = [
        %{"type" => "string", "name" => "name", "description" => "", "version" => 1},
        %{"type" => "integer", "name" => "age", "description" => "", "version" => 1}
      ]

      {:ok, result} = Dictionary.encode(dictionary)

      assert expected == Jason.decode!(result)
    end

    test "will return error tuple when encoding fails" do
      dictionary = [
        {:one, 2}
      ]

      {:error, expected} = Jason.encode(dictionary)

      assert {:error, expected} == Dictionary.encode(dictionary)
    end
  end

  describe "decode/1" do
    test "decodes json back into list of type structs" do
      json =
        [
          %{"type" => "string", "name" => "name", "description" => "", "version" => 1},
          %{"type" => "integer", "name" => "age", "description" => "", "version" => 1}
        ]
        |> Jason.encode!()

      expected = [
        %Dictionary.Type.String{name: "name"},
        %Dictionary.Type.Integer{name: "age"}
      ]

      assert {:ok, expected} == Dictionary.decode(json)
    end

    test "returns error tuple if given bad json" do
      json = "{\"one\""

      {:error, expected} = Jason.decode(json)

      assert {:error, expected} == Dictionary.decode(json)
    end

    test "returns error tuple if one field is bad" do
      json = [
        %{"type" => "string", "name" => "name", "description" => "", "version" => 1},
        %{"type" => "car", "make" => "ford", "model" => "mustang"}
      ]

      expected =
        Dictionary.InvalidFieldError.exception(
          message: "car is not a valid type",
          field: %{"type" => "car", "make" => "ford", "model" => "mustang"}
        )

      assert {:error, expected} == Dictionary.decode(json)
    end

    test "returns error tuple if nested field is bad" do
      json = [
        %{
          "type" => "map",
          "name" => "pet",
          "description" => "",
          "version" => 1,
          "fields" => [
            %{"type" => "animal", "species" => "canine"}
          ]
        }
      ]

      expected =
        Dictionary.InvalidFieldError.exception(
          message: "animal is not a valid type",
          field: %{"type" => "animal", "species" => "canine"}
        )

      assert {:error, expected} == Dictionary.decode(json)
    end
  end
end

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
      dictionary = [<<80, 75, 3, 4, 20, 0, 6, 0, 8, 0, 0, 0, 33, 0, 235, 122, 210>>]

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

      expected = Dictionary.InvalidTypeError.exception(message: "car is not a valid type")

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

      expected = Dictionary.InvalidTypeError.exception(message: "animal is not a valid type")

      assert {:error, expected} == Dictionary.decode(json)
    end
  end

  describe "normalize/2" do
    test "normalized a correct payload" do
      dictionary = [
        %Dictionary.Type.String{name: "name"},
        %Dictionary.Type.Integer{name: "age"}
      ]

      payload = %{
        "name" => "brian",
        "age" => 21
      }

      assert {:ok, payload} == Dictionary.normalize(dictionary, payload)
    end

    test "payload is put through type coercion" do
      dictionary = [
        %Dictionary.Type.String{name: "name"},
        %Dictionary.Type.Integer{name: "age"}
      ]

      payload = %{
        "name" => :brian,
        "age" => "21"
      }

      expected = %{
        "name" => "brian",
        "age" => 21
      }

      assert {:ok, expected} == Dictionary.normalize(dictionary, payload)
    end

    test "reports all errors found during normalization" do
      dictionary = [
        %Dictionary.Type.String{name: "name"},
        %Dictionary.Type.Integer{name: "age"},
        %Dictionary.Type.Map{
          name: "spouse",
          fields: [
            %Dictionary.Type.String{name: "name"},
            %Dictionary.Type.Integer{name: "age"}
          ]
        }
      ]

      payload = %{
        "name" => {:one, :two},
        "age" => "one",
        "spouse" => %{
          "name" => "shelly",
          "age" => "twenty-one"
        }
      }

      expected = %{
        "name" => :invalid_string,
        "age" => :invalid_integer,
        "spouse" => %{"age" => :invalid_integer}
      }

      assert {:error, expected} == Dictionary.normalize(dictionary, payload)
    end
  end
end

defmodule DictionaryTest do
  use ExUnit.Case

  describe "dictionary data structure" do
    setup do
      dictionary = Dictionary.from_list([
        Dictionary.Type.String.new!(name: "name"),
        Dictionary.Type.Integer.new!(name: "age"),
        Dictionary.Type.Date.new!(name: "birthdate", format: "%Y-%m-%d")
      ])

      [dictionary: dictionary]
    end

    test "get_field returns field by name", %{dictionary: dictionary} do
      assert Dictionary.Type.String.new!(name: "name") == Dictionary.get_field(dictionary, "name")
    end

    test "update_field update field in dictionary", %{dictionary: dictionary} do
      new_dictionary =
        Dictionary.update_field(
          dictionary,
          "name",
          Dictionary.Type.String.new!(name: "full_name")
        )

      assert Dictionary.Type.String.new!(name: "full_name") ==
               Dictionary.get_field(new_dictionary, "full_name")

      assert nil == Dictionary.get_field(new_dictionary, "name")
    end

    test "update_field can also update field via function", %{dictionary: dictionary} do
      new_dictionary =
        Dictionary.update_field(dictionary, "name", fn field ->
          %{field | name: "full_name"}
        end)

      assert Dictionary.Type.String.new!(name: "full_name") ==
               Dictionary.get_field(new_dictionary, "full_name")

      assert nil == Dictionary.get_field(new_dictionary, "name")
    end

    test "delete_field will remove the field from thje dictionary and maintain the indexes", %{dictionary: dictionary} do
     new_dictionary = Dictionary.delete_field(dictionary, "age")

     assert Enum.to_list(new_dictionary) == [
       Dictionary.Type.String.new!(name: "name"),
       Dictionary.Type.Date.new!(name: "birthdate", format: "%Y-%m-%d")
     ]
    end
  end

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
          "dictionary" => [
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
      dictionary =
        [
          Dictionary.Type.String.new!(name: "name"),
          Dictionary.Type.Integer.new!(name: "age"),
          Dictionary.Type.Map.new!(
            name: "spouse",
            dictionary: [
              %Dictionary.Type.String{name: "name"},
              %Dictionary.Type.Integer{name: "age"}
            ]
          )
        ]
        |> Dictionary.from_list()

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

  describe "Access" do
    setup do
      dictionary =
        Dictionary.from_list([
          Dictionary.Type.String.new!(name: "name"),
          Dictionary.Type.Integer.new!(name: "age"),
          Dictionary.Type.Date.new!(name: "birthdate", format: "%Y-%m-%d"),
          Dictionary.Type.Map.new!(
            name: "spouse",
            dictionary: [
              Dictionary.Type.String.new!(name: "name"),
              Dictionary.Type.Integer.new!(name: "age"),
              Dictionary.Type.String.new!(name: "nickname")
            ]
          )
        ])

      [dictionary: dictionary]
    end

    test "can access field of dictionary", %{dictionary: dictionary} do
      assert dictionary["name"] == Dictionary.get_field(dictionary, "name")
    end

    test "it handle fields that don't exist", %{dictionary: dictionary} do
      assert dictionary["nickname"] == nil
    end

    test "can update the field in dictionary", %{dictionary: dictionary} do
      result =
        update_in(dictionary, ["birthdate"], fn field ->
          %{field | name: "other_date"}
        end)

      assert Dictionary.get_field(result, "other_date") ==
               Dictionary.Type.Date.new!(name: "other_date", format: "%Y-%m-%d")
    end

    test "can pop field in dictionary", %{dictionary: dictionary} do
      {_, result} =
        pop_in(dictionary, ["birthdate"])

      assert nil == Dictionary.get_field(result, "birthdate")
    end

    test "can pop using get_and_update_in", %{dictionary: dictionary} do
      {field, result} = get_and_update_in(dictionary, ["birthdate"], fn _ -> :pop end)

      assert field == Dictionary.Type.Date.new!(name: "birthdate", format: "%Y-%m-%d")

      assert nil == Dictionary.get_field(result, "birthdate")
    end
  end
end

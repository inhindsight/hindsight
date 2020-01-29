defmodule Transformer.DeleteFieldTest do
  use ExUnit.Case
  import Checkov

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
        ),
        Dictionary.Type.List.new!(
          name: "friends",
          item_type: Dictionary.Type.Map,
          dictionary: [
            Dictionary.Type.String.new!(name: "name"),
            Dictionary.Type.Integer.new!(name: "age")
          ]
        )
      ])

    [dictionary: dictionary]
  end

  describe "transform_dictionary" do
    data_test "removes fields from the dictionary", %{dictionary: dictionary} do
      # step = %Transformer.DeleteField{name: ["birthdate", "spouse.nickname", "friends.age"]}
      step = Transformer.DeleteField.new!(name: name)
      assert {:ok, new_dict} = Transformer.Step.transform_dictionary(step, dictionary)

      path = Dictionary.Access.to_access_path(name)

      assert nil == get_in(new_dict, path)

      where([
        [:name],
        ["birthdate"],
        [["spouse", "nickname"]],
        [["friends", "age"]]
      ])
    end
  end

  describe "create_function" do
    data_test "will delete the configured fields from the payload", %{dictionary: dictionary} do
      step = %Transformer.DeleteField{
        # name: ["birthdate", "spouse.nickname", "colors", "friends.age"]
        name: name
      }

      value = %{
        "name" => "Gary",
        "age" => 34,
        "birthdate" => Date.new(2001, 01, 10) |> elem(1) |> Date.to_iso8601(),
        "spouse" => %{
          "name" => "Jennifer",
          "age" => 32,
          "nickname" => "Jenny"
        },
        "friends" => [
          %{"name" => "Fred", "age" => 40},
          %{"name" => "John", "age" => 30}
        ]
      }

      path = Dictionary.Access.to_access_path(name)

      {:ok, function} = Transformer.Step.create_function(step, dictionary)
      {:ok, result} = function.(value)

      {_, expected} = pop_in(value, path)

      assert result == expected

      where([
        [:name],
        ["birthdate"]
      ])
    end
  end
end

defmodule Transform.DeleteFieldsTest do
  use ExUnit.Case

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
    test "removes fields from the dictionary", %{dictionary: dictionary} do
      step = %Transform.DeleteFields{names: ["birthdate", "spouse.nickname", "friends.age"]}
      assert {:ok, new_dict} = Transform.Step.transform_dictionary(step, dictionary)

      assert nil == Dictionary.get_field(new_dict, "birthdate")
      assert nil == get_in(new_dict, ["spouse", "nickname"])
      assert nil == get_in(new_dict, ["friends", "age"])
    end
  end

  describe "transform_function" do
    test "will delete the configured fields from the payload", %{dictionary: dictionary} do
      step = %Transform.DeleteFields{
        names: ["birthdate", "spouse.nickname", "colors", "friends.age"]
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

      {:ok, function} = Transform.Step.transform_function(step, dictionary)
      result = function.(value)

      assert result == %{
               "name" => "Gary",
               "age" => 34,
               "spouse" => %{
                 "name" => "Jennifer",
                 "age" => 32
               },
               "friends" => [
                 %{"name" => "Fred"},
                 %{"name" => "John"}
               ]
             }
    end
  end
end

defmodule Transform.RenameFieldTest do
  use ExUnit.Case
  import Checkov

  import Dictionary.Access, only: [key: 1]

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

    data = %{
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

    [dictionary: dictionary, data: data]
  end

  describe "transform_dictionary" do
    data_test "renames field in dictionary", %{dictionary: dictionary} do
      step = %Transform.RenameField{from: from, to: to}

      assert {:ok, new_dictionary} = Transform.Step.transform_dictionary(step, dictionary)

      assert Dictionary.Type.String.new!(name: to) == get_in(new_dictionary, expected_path)
      from_keyed_path = from |> String.split(".") |> Enum.map(&key/1)
      assert nil == get_in(new_dictionary, from_keyed_path)

      where([
        [:from, :to, :expected_path],
        ["name", "fullname", ["fullname"]],
        ["spouse.name", "fullname", ["spouse", "fullname"]],
        ["friends.name", "fullname", ["friends", "fullname"]]
      ])
    end

    test "handles a non existent field", %{dictionary: dictionary} do
      step = %Transform.RenameField{from: "spouse.fake", to: "something"}

      assert {:ok, new_dictionary} = Transform.Step.transform_dictionary(step, dictionary)

      assert dictionary == new_dictionary
    end
  end

  describe "transform_function" do
    data_test "will rename field in data", %{data: data, dictionary: dictionary} do
      step = %Transform.RenameField{from: from, to: to}

      {:ok, function} = Transform.Step.transform_function(step, dictionary)

      [transformed_data] = function.([data]) |> Enum.to_list()
      keyed_expected_path = Enum.map(expected_path, &key/1)
      assert expected == get_in(transformed_data, keyed_expected_path)

      where([
        [:from, :to, :expected_path, :expected],
        ["name", "fullname", ["fullname"], "Gary"],
        ["spouse.name", "fullname", ["spouse", "fullname"], "Jennifer"],
        ["friends.name", "fullname", ["friends", "fullname"], ["Fred", "John"]]
      ])
    end
  end
end

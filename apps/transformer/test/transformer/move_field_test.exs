defmodule Transformer.MoveFieldTest do
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
      step = %Transformer.MoveField{from: from, to: to}

      from_path = Dictionary.Access.to_access_path(from)
      to_path = Dictionary.Access.to_access_path(to)

      assert {:ok, new_dictionary} = Transformer.Step.transform_dictionary(step, dictionary)
      new_name = List.wrap(to) |> List.last()

      assert Dictionary.Type.String.new!(name: new_name) == get_in(new_dictionary, to_path)
      assert nil == get_in(new_dictionary, from_path)

      where([
        [:from, :to],
        ["name", "fullname"],
        [["spouse", "name"], ["spouse", "fullname"]],
        [["friends", "name"], ["friends", "fullname"]]
      ])
    end

    test "handles a non existent field", %{dictionary: dictionary} do
      step = %Transformer.MoveField{from: ["spouse", "fake"], to: "something"}

      assert {:ok, new_dictionary} = Transformer.Step.transform_dictionary(step, dictionary)

      assert dictionary == new_dictionary
    end
  end

  describe "transform_function" do
    data_test "will rename field in data", %{data: data, dictionary: dictionary} do
      step = %Transformer.MoveField{from: from, to: to}

      {:ok, function} = Transformer.Step.create_function(step, dictionary)

      {:ok, transformed_data} = function.(data)

      from_path = Dictionary.Access.to_access_path(from)
      to_path = Dictionary.Access.to_access_path(to)

      assert expected_value == get_in(transformed_data, to_path)
      assert [] == get_in(transformed_data, from_path) |> List.wrap() |> Enum.reject(&is_nil/1)

      where([
        [:from, :to, :expected_value],
        ["name", "fullname", "Gary"],
        [["spouse", "name"], ["spouse", "fullname"], "Jennifer"],
        [["friends", "name"], ["friends", "fullname"], ["Fred", "John"]]
      ])
    end
  end
end

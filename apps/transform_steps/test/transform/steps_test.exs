defmodule Transform.StepsTest do
  use ExUnit.Case

  describe "transform_dictionary" do
    test "returns transformed dictionary" do
      steps = [
        %Transform.Test.Steps.SimpleRename{from: "name", to: "full_name"}
      ]

      dictionary =
        [
          Dictionary.Type.String.new!(name: "name"),
          Dictionary.Type.Integer.new!(name: "age")
        ]
        |> Dictionary.from_list()

      assert {:ok, result} = Transform.Steps.transform_dictionary(steps, dictionary)

      assert result ==
               [
                 Dictionary.Type.String.new!(name: "full_name"),
                 Dictionary.Type.Integer.new!(name: "age")
               ]
               |> Dictionary.from_list()
    end

    test "return error tuple when any step fails" do
      steps = [
        %Transform.Test.Steps.SimpleRename{from: "name", to: "full_name"},
        %Transform.Test.Steps.Error{error: "failed"}
      ]

      dictionary =
        [
          Dictionary.Type.String.new!(name: "name"),
          Dictionary.Type.Integer.new!(name: "age")
        ]
        |> Dictionary.from_list()

      assert {:error, "failed"} = Transform.Steps.transform_dictionary(steps, dictionary)
    end
  end

  describe "transform_function" do
    test "transforms stream" do
      steps = [
        %Transform.Test.Steps.TransformStream{
          transform: fn x -> Map.put(x, "age", x["age"] * 2) end
        },
        %Transform.Test.Steps.SimpleRename{from: "age", to: "years_alive"}
      ]

      dictionary =
        [
          Dictionary.Type.String.new!(name: "name"),
          Dictionary.Type.Integer.new!(name: "age")
        ]
        |> Dictionary.from_list()

      value = %{"name" => "joe", "age" => 10}

      assert {:ok, transformer} = Transform.Steps.create_transformer(steps, dictionary)
      assert {:ok, transformed_value} = transformer.(value)

      assert transformed_value == %{"name" => "joe", "years_alive" => 20}
    end

    test "ensure correct dictionary is given to each step" do
      steps = [
        %Transform.Test.Steps.SimpleRename{from: "age", to: "years_alive"},
        %Transform.Test.Steps.TransformInteger{
          name: "years_alive",
          transform: fn x -> Map.put(x, "years_alive", x["years_alive"] * 2) end
        },
        %Transform.Test.Steps.SimpleRename{from: "years_alive", to: "some_number"}
      ]

      dictionary =
        [
          Dictionary.Type.String.new!(name: "name"),
          Dictionary.Type.Integer.new!(name: "age")
        ]
        |> Dictionary.from_list()

      value = %{"name" => "joe", "age" => 10}

      assert {:ok, transformer} = Transform.Steps.create_transformer(steps, dictionary)
      assert {:ok, transformed_value} = transformer.(value)

      assert transformed_value == %{"name" => "joe", "some_number" => 20}
    end
  end
end

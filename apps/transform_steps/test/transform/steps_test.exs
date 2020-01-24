defmodule Transform.StepsTest do
  use ExUnit.Case

  describe "prepare" do
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

      assert {:ok, transformer} = Transform.Steps.create_transformer(steps, dictionary)
      result = Transform.Steps.outgoing_dictionary(transformer)

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

      assert {:error, "failed"} = Transform.Steps.create_transformer(steps, dictionary)
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

      stream = [%{"name" => "joe", "age" => 10}, %{"name" => "bob", "age" => 27}]

      assert {:ok, transformer} = Transform.Steps.create_transformer(steps, dictionary)
      assert {:ok, stream} = Transform.Steps.transform(transformer, stream)

      assert Enum.to_list(stream) == [
               %{"name" => "joe", "years_alive" => 20},
               %{"name" => "bob", "years_alive" => 54}
             ]
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

      stream = [%{"name" => "joe", "age" => 10}, %{"name" => "bob", "age" => 27}]

      assert {:ok, transformer} = Transform.Steps.create_transformer(steps, dictionary)
      assert {:ok, stream} = Transform.Steps.transform(transformer, stream)

      assert Enum.to_list(stream) == [
               %{"name" => "joe", "some_number" => 20},
               %{"name" => "bob", "some_number" => 54}
             ]
    end
  end
end

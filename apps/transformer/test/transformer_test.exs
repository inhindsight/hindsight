defmodule TransformerTest do
  use ExUnit.Case

  describe "transform_dictionary" do
    test "returns transformed dictionary" do
      steps = [
        %Transformer.Test.SimpleRename{from: "name", to: "full_name"}
      ]

      dictionary =
        [
          Dictionary.Type.String.new!(name: "name"),
          Dictionary.Type.Integer.new!(name: "age")
        ]
        |> Dictionary.from_list()

      assert {:ok, result} = Transformer.transform_dictionary(steps, dictionary)

      assert Enum.to_list(result) == [
               Dictionary.Type.String.new!(name: "full_name"),
               Dictionary.Type.Integer.new!(name: "age")
             ]
    end

    test "return error tuple when any step fails" do
      steps = [
        %Transformer.Test.SimpleRename{from: "name", to: "full_name"},
        %Transformer.Test.Error{error: "failed", dictionary: true}
      ]

      dictionary =
        [
          Dictionary.Type.String.new!(name: "name"),
          Dictionary.Type.Integer.new!(name: "age")
        ]
        |> Dictionary.from_list()

      assert {:error, "failed"} = Transformer.transform_dictionary(steps, dictionary)
    end
  end

  describe "transform_function" do
    test "transforms value" do
      steps = [
        %Transformer.Test.TransformStream{
          name: "age",
          transform: fn x -> x * 2 end
        },
        %Transformer.Test.SimpleRename{from: "age", to: "years_alive"}
      ]

      dictionary =
        [
          Dictionary.Type.String.new!(name: "name"),
          Dictionary.Type.Integer.new!(name: "age")
        ]
        |> Dictionary.from_list()

      value = %{"name" => "joe", "age" => 10}

      assert {:ok, transformer} = Transformer.create(steps, dictionary)
      assert {:ok, transformed_value} = transformer.(value)

      assert transformed_value == %{"name" => "joe", "years_alive" => 20}
    end

    test "ensure correct dictionary is given to each step" do
      steps = [
        %Transformer.Test.SimpleRename{from: "age", to: "years_alive"},
        %Transformer.Test.TransformInteger{
          name: "years_alive",
          transform: fn x -> x * 2 end
        },
        %Transformer.Test.SimpleRename{from: "years_alive", to: "some_number"}
      ]

      dictionary =
        [
          Dictionary.Type.String.new!(name: "name"),
          Dictionary.Type.Integer.new!(name: "age")
        ]
        |> Dictionary.from_list()

      value = %{"name" => "joe", "age" => 10}

      assert {:ok, transformer} = Transformer.create(steps, dictionary)
      assert {:ok, transformed_value} = transformer.(value)

      assert transformed_value == %{"name" => "joe", "some_number" => 20}
    end

    test "stop processing with step returns an error" do
      steps = [
        %Transformer.Test.Error{error: "something failed", transform: true},
        %Transformer.Test.TransformInteger{name: "age", transform: fn x -> x * 2 end}
      ]

      dictionary =
        Dictionary.from_list([
          Dictionary.Type.String.new!(name: "name"),
          Dictionary.Type.Integer.new!(name: "age")
        ])

      value = %{"name" => "joe", "age" => 10}

      assert {:ok, transformer} = Transformer.create(steps, dictionary)
      assert {:error, "something failed"} == transformer.(value)
    end
  end
end

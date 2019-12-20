defmodule ExtractTest do
  use Checkov

  describe "new/1" do
    data_test "validates #{field} against bad input" do
      {:ok, input} =
        DefinitionFaker.extract(%{})
        |> Ok.map(&Map.delete(&1, :__struct__))
        |> Ok.map(&put_in(&1, [field], value))

      assert {:error, [%{input: value, path: [field]} | _]} = Extract.new(input)

      where [
        [:field, :value],
        [:version, "1"],
        [:id, ""],
        [:dataset_id, 2001],
        [:steps, 1]
      ]
    end
  end

  describe "execute_steps/1" do
    test "parses and executes steps" do
      steps = [
        %{
          step: "Test.Steps.CreateResponse",
          response: %{
            body: [1, 2, 3, 4, 5, 6]
          }
        },
        %{
          step: "Test.Steps.SetStream"
        },
        %{
          step: "Test.Steps.TransformStream",
          transform: fn x -> x * 2 end
        }
      ]

      {:ok, result} = Extract.execute_steps(steps)

      assert Enum.to_list(result) == [2, 4, 6, 8, 10, 12]
    end

    test "returns error tuple when given invalid key to step" do
      steps = [
        %{
          step: "Test.Steps.CreateResponse",
          value: "one"
        }
      ]

      message = "key :value not found in: %Test.Steps.CreateResponse{response: nil}"
      assert {:error, message} == Extract.execute_steps(steps)
    end

    test "returns error tuple when given invalid step" do
      steps = [
        %{
          step: "Test.Steps.Invalid",
          field: "value"
        }
      ]

      message =
        "function Test.Steps.Invalid.__struct__/1 is undefined (module Test.Steps.Invalid is not available)"

      assert {:error, message} == Extract.execute_steps(steps)
    end
  end
end

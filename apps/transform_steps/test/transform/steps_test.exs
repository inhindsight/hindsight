defmodule Transform.StepsTest do
  use ExUnit.Case

  describe "execute/1" do
    test "parses and executes steps" do
      steps = [
        %{
          step: "Transform.Test.Steps.SetStream",
          stream: [1, 2, 3, 4, 5, 6]
        },
        %{
          step: "Transform.Test.Steps.TransformStream",
          transform: fn x -> x * 2 end
        }
      ]

      {:ok, result} = Transform.Steps.execute(steps)

      assert Enum.to_list(result) == [2, 4, 6, 8, 10, 12]
    end

    test "returns error tuple when given invalid key to step" do
      steps = [
        %{
          step: "Transform.Test.Steps.SetStream",
          value: "one"
        }
      ]

      message = "key :value not found in: %Transform.Test.Steps.SetStream{stream: nil}"
      assert {:error, message} == Transform.Steps.execute(steps)
    end

    test "returns error tuple when given invalid step" do
      steps = [
        %{
          step: "Transform.Test.Steps.Invalid",
          field: "value"
        }
      ]

      message =
        "function Transform.Test.Steps.Invalid.__struct__/1 is undefined (module Transform.Test.Steps.Invalid is not available)"

      assert {:error, message} == Transform.Steps.execute(steps)
    end
  end
end

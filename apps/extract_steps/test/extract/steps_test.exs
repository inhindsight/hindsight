defmodule Extract.StepsTest do
  use ExUnit.Case
  doctest Extract.Steps

  alias Extract.Steps.Context

  describe "execute/1" do
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

      {:ok, context} = Extract.Steps.execute(steps)

      actual = Context.get_stream(context) |> Enum.to_list()
      assert actual == [2, 4, 6, 8, 10, 12]
    end

    test "returns error tuple when given invalid key to step" do
      steps = [
        %{
          step: "Test.Steps.CreateResponse",
          value: "one"
        }
      ]

      message = "key :value not found in: %Test.Steps.CreateResponse{response: nil}"
      assert {:error, message} == Extract.Steps.execute(steps)
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

      assert {:error, message} == Extract.Steps.execute(steps)
    end
  end
end

defmodule Extract.StepsTest do
  use ExUnit.Case
  doctest Extract.Steps

  alias Extract.Context

  describe "execute/1" do
    test "parses and executes steps" do
      steps = [
        %Test.Steps.CreateResponse{response: %{body: [1, 2, 3, 4, 5, 6]}},
        %Test.Steps.SetStream{},
        %Test.Steps.TransformStream{transform: fn x -> x * 2 end}
      ]

      {:ok, context} = Extract.Steps.execute(steps)

      actual = Context.get_stream(context) |> Enum.to_list()
      assert actual == [2, 4, 6, 8, 10, 12]
    end
  end
end

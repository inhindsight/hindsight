defmodule Decode.CsvTest do
  use ExUnit.Case

  alias Extract.Steps.Context

  test "parses context stream into csv" do
    step = %Decode.Csv{
      headers: ["name", "age"],
      skip_first_line: false
    }

    stream = ["brian,21\nrick,34", "johnson,45", "greg,89"]
    context = Context.new() |> Context.set_stream(stream)

    {:ok, context} = Extract.Step.execute(step, context)

    assert Enum.to_list(context.stream) == [
             %{"name" => "brian", "age" => "21"},
             %{"name" => "rick", "age" => "34"},
             %{"name" => "johnson", "age" => "45"},
             %{"name" => "greg", "age" => "89"}
           ]
  end

  test "returns error tuple when stream not available" do
    step = %Decode.Csv{
      headers: ["name", "age"],
      skip_first_line: false
    }

    {:error, reason} = Extract.Step.execute(step, Context.new())

    assert reason ==
             Extract.InvalidContextError.exception(
               message: "There is no stream available in the context.",
               step: step
             )
  end
end

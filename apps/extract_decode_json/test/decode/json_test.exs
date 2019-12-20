defmodule Decode.JsonTest do
  use ExUnit.Case

  alias Extract.Context

  test "decodes context stream to json" do
    stream = [
      ~s([),
      ~s({\"name\": \"Kyle\", \"age\": 2},{\"name\": \"Joe\"),
      ~s(, \"age\": 21},{\"name\": \"Bobby\",\"age\": 62}),
      ~s(])
    ]

    context = Context.new() |> Context.set_stream(stream)
    {:ok, context} = Extract.Step.execute(%Decode.Json{}, context)

    expected = Enum.join(stream) |> Jason.decode!()
    assert context.stream == expected
  end

  test "returns error tuple when stream is not available" do
    {:error, reason} = Extract.Step.execute(%Decode.Json{}, Context.new())

    expected =
      Extract.InvalidContextError.exception(message: "Invalid stream", step: %Decode.Json{})

    assert reason == expected
  end

  test "returns error tuple when stream is not valid Json" do
    stream = [
      ~s([\"howdy\": \"duty\"])
    ]

    context = Context.new() |> Context.set_stream(stream)
    result = Extract.Step.execute(%Decode.Json{}, context)

    error_tuple = Enum.join(stream) |> Jason.decode()
    assert result == error_tuple
  end
end

defmodule Decode.JsonLinesTest do
  use ExUnit.Case

  alias Extract.Context

  test "decodes json lines file as a stream" do
    stream = [
      json(%{"name" => "john", "age" => 21}) <> "\n" <> json(%{"name" => "Fred", "age" => 34}),
      "\n" <> json(%{"name" => "george", "age" => 36}) <> "\n"
    ]

    context = Context.new() |> Context.set_stream(stream)
    {:ok, context} = Extract.Step.execute(%Decode.JsonLines{}, context)

    assert Enum.to_list(context.stream) == [
             %{"name" => "john", "age" => 21},
             %{"name" => "Fred", "age" => 34},
             %{"name" => "george", "age" => 36}
           ]
  end

  test "returns error tuple when stream is not available" do
    {:error, reason} = Extract.Step.execute(%Decode.JsonLines{}, Context.new())

    expected =
      Extract.InvalidContextError.exception(message: "Invalid stream", step: %Decode.JsonLines{})

    assert reason == expected
  end

  defp json(map), do: Jason.encode!(map)
end

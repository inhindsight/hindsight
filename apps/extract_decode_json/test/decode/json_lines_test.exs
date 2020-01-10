defmodule Decode.JsonLinesTest do
  use ExUnit.Case

  alias Extract.Steps.Context

  test "decodes json lines file as a stream" do
    source = fn _ ->
      [
        json(%{"name" => "john", "age" => 21}),
        json(%{"name" => "Fred", "age" => 34}),
        json(%{"name" => "george", "age" => 36})
      ]
    end

    context = Context.new() |> Context.set_source(source)
    {:ok, context} = Extract.Step.execute(%Decode.JsonLines{}, context)

    assert Context.get_stream(context) |> Enum.to_list() == [
             %{"name" => "john", "age" => 21},
             %{"name" => "Fred", "age" => 34},
             %{"name" => "george", "age" => 36}
           ]
  end

  defp json(map), do: Jason.encode!(map)
end

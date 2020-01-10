defmodule Decode.JsonTest do
  use ExUnit.Case

  alias Extract.Steps.Context

  test "decodes context stream to json" do
    source = fn _ ->
      [
        ~s([),
        ~s({\"name\": \"Kyle\", \"age\": 2},{\"name\": \"Joe\"),
        ~s(, \"age\": 21},{\"name\": \"Bobby\",\"age\": 62}),
        ~s(])
      ]
    end

    context = Context.new() |> Context.set_source(source)
    {:ok, context} = Extract.Step.execute(%Decode.Json{}, context)

    expected = [
      %{"name" => "Kyle", "age" => 2},
      %{"name" => "Joe", "age" => 21},
      %{"name" => "Bobby", "age" => 62}
    ]
    assert Context.get_stream(context) == expected
  end

end

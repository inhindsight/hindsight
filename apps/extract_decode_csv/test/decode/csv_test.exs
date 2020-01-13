defmodule Decode.CsvTest do
  use ExUnit.Case

  alias Extract.Steps.Context

  test "parses context stream into csv" do
    step = %Decode.Csv{
      headers: ["name", "age"],
      skip_first_line: false
    }

    source = fn _ -> ["brian,21\n", "rick,34", "johnson,45\n", "greg,89"] end
    context = Context.new() |> Context.set_source(source)

    {:ok, context} = Extract.Step.execute(step, context)

    stream = Context.get_stream(context) |> Enum.to_list()

    assert stream == [
             %{"name" => "brian", "age" => "21"},
             %{"name" => "rick", "age" => "34"},
             %{"name" => "johnson", "age" => "45"},
             %{"name" => "greg", "age" => "89"}
           ]
  end
end

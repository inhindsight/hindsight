NimbleCSV.define(Decode.Csv.Parser, [])

defmodule Decode.Csv do
  @enforce_keys [:headers]
  defstruct headers: nil,
            skip_first_line: false

  defimpl Extract.Step, for: Decode.Csv do
    import Extract.Steps.Context

    def execute(%Decode.Csv{} = step, context) do
      source = fn opts ->
        get_stream(context, opts)
        |> Decode.Csv.Parser.parse_stream(skip_headers: step.skip_first_line)
        |> Stream.map(&Enum.zip(step.headers, &1))
        |> Stream.map(&Map.new/1)
      end

      context
      |> set_source(source)
      |> Ok.ok()
    end
  end
end

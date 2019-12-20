NimbleCSV.define(Decode.Csv.Parser, [])

defmodule Decode.Csv do
  @enforce_keys [:headers]
  defstruct headers: nil,
            skip_first_line: true

  defimpl Extract.Step, for: Decode.Csv do
    import Extract.Context

    def execute(%Decode.Csv{} = step, %{stream: nil} = _context) do
      message = "There is no stream available in the context."
      {:error, Extract.InvalidContextError.exception(message: message, step: step)}
    end

    def execute(%Decode.Csv{} = step, context) do
      new_stream =
        context.stream
        |> Stream.flat_map(&String.split(&1, "\n"))
        |> Decode.Csv.Parser.parse_stream(skip_headers: step.skip_first_line)
        |> Stream.map(fn row -> Enum.zip(step.headers, row) |> Map.new() end)

      {:ok, set_stream(context, new_stream)}
    end
  end
end

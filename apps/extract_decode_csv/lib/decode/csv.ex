NimbleCSV.define(Decode.Csv.Parser, [])

defmodule Decode.Csv do
  @enforce_keys [:headers]
  defstruct headers: nil,
            skip_first_line: false

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
        |> Stream.map(&Enum.zip(step.headers, &1))
        |> Stream.map(&Map.new/1)

      {:ok, set_stream(context, new_stream)}
    end
  end
end

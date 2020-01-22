NimbleCSV.define(Extract.Decode.Csv.Parser, [])

defmodule Extract.Decode.Csv do
  use Definition, schema: Extract.Decode.Csv.V1

  @type t :: %__MODULE__{
          version: integer,
          headers: list,
          skip_first_line: boolean
        }

  @derive Jason.Encoder
  defstruct version: 1,
            headers: nil,
            skip_first_line: false

  defimpl Extract.Step, for: __MODULE__ do
    import Extract.Steps.Context

    def execute(step, context) do
      source = fn opts ->
        get_stream(context, opts)
        |> Extract.Decode.Csv.Parser.parse_stream(skip_headers: step.skip_first_line)
        |> Stream.map(&Enum.zip(step.headers, &1))
        |> Stream.map(&Map.new/1)
      end

      context
      |> set_source(source)
      |> Ok.ok()
    end
  end
end

defmodule Extract.Decode.Csv.V1 do
  use Definition.Schema

  def s do
    schema(%Extract.Decode.Csv{
      version: version(1),
      headers: spec(is_list() and not_nil?()),
      skip_first_line: spec(is_boolean() and not_nil?())
    })
  end
end

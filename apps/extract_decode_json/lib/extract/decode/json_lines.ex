defmodule Extract.Decode.JsonLines do
  use Definition, schema: Extract.Decode.JsonLines.V1

  @derive Jason.Encoder
  defstruct []

  defimpl Extract.Step, for: __MODULE__ do
    import Extract.Steps.Context

    def execute(_step, context) do
      source = fn opts ->
        get_stream(context, opts)
        |> Stream.map(&Jason.decode!/1)
      end

      context
      |> set_source(source)
      |> Ok.ok()
    end
  end
end

defmodule Extract.Decode.JsonLines.V1 do
  use Definition.Schema

  def s do
    schema(%Extract.Decode.JsonLines{})
  end
end

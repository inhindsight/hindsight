defmodule Decode.JsonLines do
  defstruct []

  defimpl Extract.Step, for: Decode.JsonLines do
    import Extract.Steps.Context

    def execute(%Decode.JsonLines{}, context) do
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

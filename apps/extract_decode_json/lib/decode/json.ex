defmodule Decode.Json do
  defstruct []

  defimpl Extract.Step, for: Decode.Json do
    import Extract.Steps.Context

    def execute(%Decode.Json{}, context) do
      source = fn opts ->
        get_stream(context, opts)
        |> Enum.join()
        |> Jason.decode!()
        |> List.wrap()
      end

      context
      |> set_source(source)
      |> Ok.ok()
    end
  end
end

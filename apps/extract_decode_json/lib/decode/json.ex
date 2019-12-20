defmodule Decode.Json do
  defstruct []

  defimpl Extract.Step, for: Decode.Json do
    import Extract.Context

    def execute(%Decode.Json{} = step, %{stream: nil} = _context) do
      Extract.InvalidContextError.exception(message: "Invalid stream", step: step)
      |> Ok.error()
    end

    def execute(%Decode.Json{}, context) do
      context.stream
      |> Enum.join()
      |> Jason.decode()
      |> Ok.map(&set_stream(context, &1))
    end
  end
end

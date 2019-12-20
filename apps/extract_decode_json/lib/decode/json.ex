defmodule Decode.Json do
  defstruct []

  defimpl Extract.Step, for: Decode.Json do
    import Extract.Context

    def execute(%Decode.Json{} = step, %{stream: nil} = _context) do
      Extract.InvalidContextError.exception(message: "Invalid stream", step: step)
      |> Ok.error()
    end

    def execute(%Decode.Json{}, context) do
      with json_body <- Enum.join(context.stream),
           {:ok, decoded_json} <- Jason.decode(json_body) do
        set_stream(context, decoded_json)
        |> Ok.ok()
      end
    end
  end
end

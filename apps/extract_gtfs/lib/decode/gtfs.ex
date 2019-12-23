defmodule Decode.Gtfs do
  defstruct []

  defmodule InvalidGtfsError do
    defexception [:message, :bytes]
  end

  defimpl Extract.Step, for: Decode.Gtfs do
    import Extract.Steps.Context

    def execute(%Decode.Gtfs{} = step, %{stream: nil}) do
      Extract.InvalidContextError.exception(message: "Invalid stream", step: step)
      |> Ok.error()
    end

    def execute(%Decode.Gtfs{} = _step, context) do
      message = TransitRealtime.FeedMessage.decode(context.stream)

      context
      |> set_stream(message.entity)
      |> Ok.ok()
    rescue
      e ->
        InvalidGtfsError.exception(message: error_message(e), bytes: context.stream)
        |> Ok.error()
    end

    defp error_message(error) do
      case Exception.exception?(error) do
        true -> Exception.message(error)
        false -> error
      end
    end
  end
end

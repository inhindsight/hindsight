defmodule Decode.Gtfs do
  defstruct []

  defimpl Extract.Step, for: Decode.Gtfs do
    import Extract.Steps.Context

    def execute(%Decode.Gtfs{}, context) do
      source = fn opts ->
        opts = Keyword.put(opts, :read, :bytes)

        get_stream(context, opts)
        |> Enum.join()
        |> TransitRealtime.FeedMessage.decode()
        |> Map.get(:entity)
      end

      context
      |> set_source(source)
      |> Ok.ok()
    end
  end
end

defmodule Extract.Decode.Gtfs do
  use Definition, schema: Extract.Decode.Gtfs.V1

  @derive Jason.Encoder
  defstruct []

  defimpl Extract.Step, for: __MODULE__ do
    import Extract.Context

    def execute(_step, context) do
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

defmodule Extract.Decode.Gtfs.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Extract.Decode.Gtfs{})
  end
end

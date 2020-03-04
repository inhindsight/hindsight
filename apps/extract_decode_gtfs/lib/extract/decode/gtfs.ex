defmodule Extract.Decode.Gtfs do
  use Definition, schema: Extract.Decode.Gtfs.V1

  @derive Jason.Encoder
  defstruct []

  defimpl Extract.Step, for: __MODULE__ do
    import Extract.Context

    def execute(_step, context) do
      source = fn opts ->
        opts = Keyword.put(opts, :read, :bytes)

        data_list = get_stream(context, opts) |> Enum.to_list() |> List.flatten()
        meta = List.last(data_list) |> Map.get(:meta)

        data_list
        |> Enum.map(&Map.get(&1, :data))
        |> Enum.join()
        |> TransitRealtime.FeedMessage.decode()
        |> Map.get(:entity)
        |> Enum.map(&decode_struct/1)
        |> Enum.map(&Extract.Message.new(data: &1, meta: meta))
        |> Stream.chunk_every(chunk_size(opts))
      end

      context
      |> set_source(source)
      |> Ok.ok()
    end

    defp decode_struct(%_struct{} = entity) do
      entity
      |> Map.from_struct()
      |> Map.new(fn {k, v} -> {Atom.to_string(k), decode_struct(v)} end)
    end

    defp decode_struct(element), do: element
  end
end

defmodule Extract.Decode.Gtfs.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Extract.Decode.Gtfs{})
  end
end

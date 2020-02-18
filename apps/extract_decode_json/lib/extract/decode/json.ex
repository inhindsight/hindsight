defmodule Extract.Decode.Json do
  use Definition, schema: Extract.Decode.Json.V1

  @derive Jason.Encoder
  defstruct []

  defimpl Extract.Step, for: __MODULE__ do
    import Extract.Context

    def execute(_step, context) do
      source = fn opts ->
        data_list = get_stream(context, opts) |> Enum.to_list()
        meta = List.last(data_list) |> Map.get(:meta)

        data_list
        |> Enum.map(&Map.get(&1, :data))
        |> Enum.join()
        |> Jason.decode!()
        |> List.wrap()
        |> Enum.map(&Extract.Message.new(data: &1, meta: meta))
      end

      context
      |> set_source(source)
      |> Ok.ok()
    end
  end
end

defmodule Extract.Decode.Json.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Extract.Decode.Json{})
  end
end

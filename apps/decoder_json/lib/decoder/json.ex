defmodule Decoder.Json do
  use Definition, schema: Decoder.Json.V1

  @derive Jason.Encoder
  defstruct chunk_size: 1000

  defimpl Decoder do
    def decode(t, stream) do
      stream
      |> Enum.to_list()
      |> List.flatten()
      |> Enum.join()
      |> Jason.decode!()
      |> List.wrap()
      |> Stream.chunk_every(t.chunk_size)
    end
  end
end

defmodule Decoder.Json.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Decoder.Json{
      chunk_size: spec(is_integer())
    })
  end
end

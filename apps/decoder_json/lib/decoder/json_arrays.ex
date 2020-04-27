defmodule Decoder.JsonArrays do
  @moduledoc """
  Defines a `Decoder` impl for JSON data where the json string's top level object is an array and should be decomposed into its elements.
  """
  use Definition, schema: Decoder.JsonArrays.V1

  @derive Jason.Encoder
  defstruct []

  defimpl Decoder do
    def lines_or_bytes(_t), do: :line

    def decode(t, stream) do
      Stream.map(stream, &decode_chunk/1)
    end

    defp decode_chunk(chunk) do
      Enum.flat_map(chunk, &Jason.decode!/1)
    end
  end
end

defmodule Decoder.JsonArrays.V1 do
  @moduledoc false
  use Definition.Schema

  @impl true
  def s do
    schema(%Decoder.JsonArrays{})
  end
end

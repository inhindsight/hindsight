defmodule Decoder.JsonLines do
  use Definition, schema: Decoder.JsonLines.V1

  @derive Jason.Encoder
  defstruct []

  defimpl Decoder do

    def decode(_t, stream) do
      stream
      |> Stream.map(&decode_chunk/1)
    end

    defp decode_chunk(chunk) do
      Enum.map(chunk, &Jason.decode!/1)
    end
  end
end

defmodule Decoder.JsonLines.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Decoder.JsonLines{})
  end
end

defmodule Decoder.Gtfs do
  @moduledoc """
  Defines a `Decoder` impl for GTFS data.

  ## Configuration

  * `chunk_size` - Limits chunks by bytes. Defaults to 100.
  """
  use Definition, schema: Decoder.Gtfs.V1

  @derive Jason.Encoder
  defstruct chunk_size: 100

  defimpl Decoder do
    def lines_or_bytes(_t), do: 2048

    def decode(_t, messages) do
      messages
      |> TransitRealtime.FeedMessage.decode()
      |> Map.get(:entity)
      |> Enum.map(&Decoder.Gtfs.decode_struct/1)
    end
  end

  def decode_struct(%_struct{} = entity) do
    entity
    |> Map.from_struct()
    |> Map.new(fn {k, v} -> {Atom.to_string(k), decode_struct(v)} end)
  end

  def decode_struct(element), do: element
end

defmodule Decoder.Gtfs.V1 do
  @moduledoc false
  use Definition.Schema

  @impl true
  def s do
    schema(%Decoder.Gtfs{
      chunk_size: spec(is_integer())
    })
  end
end

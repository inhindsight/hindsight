defmodule Decoder.Json do
  @moduledoc """
  Defines a `Decoder` impl for JSON data that decodes into a single json object.

  ## Configuration

  * `chunk_size` - Streaming chunk size in bytes. Defaults to `1_000`.
  """
  use Definition, schema: Decoder.Json.V1
  use JsonSerde, alias: "decoder_json"

  @derive Jason.Encoder
  defstruct chunk_size: 1_000

  defimpl Decoder do
    def lines_or_bytes(_t), do: :line

    def decode(_t, messages) do
      messages
      |> Enum.join()
      |> Jason.decode!()
      |> List.wrap()
    end
  end
end

defmodule Decoder.Json.V1 do
  @moduledoc false
  use Definition.Schema

  @impl true
  def s do
    schema(%Decoder.Json{
      chunk_size: spec(is_integer())
    })
  end
end

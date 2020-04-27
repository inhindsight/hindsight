defmodule Decoder.JsonArrays do
  @moduledoc """
  Defines a `Decoder` impl for arrays of JSON data.
  """
  use Definition, schema: Decoder.JsonArrays.V1

  @derive Jason.Encoder
  defstruct chunk_size: 1_000

  defimpl Decoder do
    def lines_or_bytes(_t), do: :line

    def decode(_t, stream) do
      stream
      |> Jason.decode!()
      |> List.flatten()
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

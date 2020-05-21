defmodule Decoder.JsonLines do
  @moduledoc """
  Defines a `Decoder` impl for [JSON Lines](http://jsonlines.org/) data.
  """
  use Definition, schema: Decoder.JsonLines.V1

  @derive Jason.Encoder
  defstruct []

  defimpl Decoder do
    def lines_or_bytes(_t), do: :line

    def decode(_t, messages) do
      Enum.map(messages, &Jason.decode!/1)
    end
  end
end

defmodule Decoder.JsonLines.V1 do
  @moduledoc false
  use Definition.Schema

  @impl true
  def s do
    schema(%Decoder.JsonLines{})
  end
end

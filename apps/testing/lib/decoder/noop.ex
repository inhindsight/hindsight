defmodule Decoder.Noop do
  defstruct []

  def new() do
    %__MODULE__{}
  end

  defimpl Decoder do
    def lines_or_bytes(_t), do: :line

    def decode(_t, stream) do
      stream
    end
  end
end

defmodule Transform.Steps.Context do
  @type t() :: %__MODULE__{
          stream: Enumerable.t()
        }
  defstruct stream: nil

  @spec new() :: %__MODULE__{}
  def new() do
    %__MODULE__{}
  end

  @spec set_stream(context :: t, stream :: Enum.t()) :: t
  def set_stream(context, stream) do
    Map.put(context, :stream, stream)
  end
end

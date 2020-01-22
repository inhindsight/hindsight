defmodule Transform.Steps.Context do
  @type t() :: %__MODULE__{
          dictionary: Dictionary.t(),
          stream: Enumerable.t()
        }
  defstruct dictionary: nil, stream: nil

  @spec new(stream :: Enumerable.t()) :: %__MODULE__{}
  def new(stream) do
    %__MODULE__{stream: stream}
  end

  @spec get_dictionary(context :: t) :: Dictionary.t()
  def get_dictionary(context) do
    Map.get(context, :dictionary)
  end

  @spec set_dictionary(context :: t, dictionary :: Dictionary.t()) :: t
  def set_dictionary(context, dictionary) do
    Map.put(context, :dictionary, dictionary)
  end

  @spec get_stream(context :: t) :: Enumerable.t()
  def get_stream(context) do
    Map.get(context, :stream)
  end

  @spec set_stream(context :: t, stream :: Enumerable.t()) :: t
  def set_stream(context, stream) do
    Map.put(context, :stream, stream)
  end

  @spec set_dictionary(context :: t, dictionary :: Dictionary.t()) :: t
  def set_dictionary(context, dictionary) do
    Map.put(context, :dictionary, dictionary)
  end
end

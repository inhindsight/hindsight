defmodule Extract.Message do
  @moduledoc """
  Envelope for data moving through the extraction pipeline.

  ## Fields

  * `data` - Data message being processed.
  * `meta` - `Map` for optional metadata key/value pairs.
  """
  @type t :: %__MODULE__{
          data: term,
          meta: map
        }

  defstruct data: nil,
            meta: %{}

  @spec new(keyword) :: t
  def new(opts) do
    struct!(__MODULE__, opts)
  end

  @spec update_data(message :: t, (term -> term)) :: t
  def update_data(%__MODULE__{} = message, function) when is_function(function, 1) do
    %{message | data: function.(message.data)}
  end

  @spec put_meta(message :: t, key :: String.t(), value :: term) :: t
  def put_meta(%__MODULE__{} = message, key, value) do
    %{message | meta: Map.put(message.meta, key, value)}
  end

  @spec get_meta(message :: t, key :: String.t()) :: term
  def get_meta(%__MODULE__{} = message, key) do
    Map.get(message.meta, key)
  end
end

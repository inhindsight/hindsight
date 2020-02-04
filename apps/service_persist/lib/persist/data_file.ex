defmodule Persist.DataFile do
  @type t :: term
  @type file_path :: String.t()

  @callback open(destination :: String.t(), dictionary :: Dictionary.t()) ::
              {:ok, t} | {:error, term}
  @callback write(t, messages :: list()) :: {:ok, non_neg_integer} | {:error, term}
  @callback close(t) :: file_path
end

defmodule Persist.DataFile.Avro do
  @behaviour Persist.DataFile

  defdelegate open(destination, dictionary), to: Avro
  defdelegate write(avro, data), to: Avro
  defdelegate close(avro), to: Avro
end

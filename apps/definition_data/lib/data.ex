defmodule Data do
  @moduledoc """
  Defines the structure of a data message as it
  moves through the ingestion pipeline.

  Each message receives one identifier to signal
  to which dataset it belongs and a separate identifier
  to signal under which extraction event it was
  ingested.

  # Examples
    iex> Data.new(
    ...>           version: 1,
    ...>           dataset_id: "123-456",
    ...>           extract_id: "567-890",
    ...>           payload: %{hello: "world"}
    ...>         )
    {:ok,
      %Data{dataset_id: "123-456", extract_id: "567-890", payload: %{hello: "world"}, version: 1}}
  """
  use Definition, schema: Data.V1

  @derive Jason.Encoder
  defstruct version: nil,
            dataset_id: nil,
            extract_id: nil,
            payload: nil
end

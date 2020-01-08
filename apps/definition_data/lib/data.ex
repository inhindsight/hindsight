defmodule Data do
  use Definition, schema: Data.V1

  @derive Jason.Encoder
  defstruct version: nil,
            dataset_id: nil,
            extract_id: nil,
            payload: nil
end

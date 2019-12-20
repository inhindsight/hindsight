defmodule Data do
  use Definition, schema: Data.V1

  defstruct version: nil,
            gather_id: nil,
            load_id: nil,
            payload: nil
end

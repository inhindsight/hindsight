defmodule Extract do
  use Definition, schema: Extract.V1

  defstruct version: nil,
            id: nil,
            dataset_id: nil,
            steps: []
end
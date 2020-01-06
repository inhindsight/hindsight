defmodule Transform do
  use Definition, schema: Transform.V1

  defstruct version: 1,
            id: nil,
            dataset_id: nil,
            steps: []
end

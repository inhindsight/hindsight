defmodule Extract do
  use Definition, schema: Extract.V1

  @type uuid :: String.t()

  @type t :: %Extract{
          version: integer,
          id: uuid,
          dataset_id: uuid,
          name: String.t(),
          destination: String.t(),
          steps: [Extract.Step.t()]
        }

  defstruct version: 1,
            id: nil,
            dataset_id: nil,
            name: nil,
            destination: nil,
            steps: []
end

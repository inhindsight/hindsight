defmodule Transform do
  use Definition, schema: Transform.V1

  @type uuid :: String.t()

  @type t :: %__MODULE__{
    version: integer,
    id: uuid,
    dataset_id: uuid,
    dictionary: list,
    steps: list
  }

  defstruct version: 1,
            id: nil,
            dataset_id: nil,
            dictionary: [],
            steps: []
end

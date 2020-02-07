defmodule Schedule do
  use Definition, schema: Schedule.V1

  @type uuid :: String.t()

  @type t :: %__MODULE__{
          version: integer,
          id: uuid,
          dataset_id: String.t(),
          subset_id: String.t(),
          cron: String.t(),
          extract: Extract.t(),
          transform: Transform.t(),
          load: list
        }

  defstruct version: 1,
            id: nil,
            dataset_id: nil,
            subset_id: nil,
            cron: nil,
            extract: nil,
            transform: nil,
            load: []
end

defmodule Schedule do
  use Definition, schema: Schedule.V1

  defstruct version: 1,
            id: nil,
            dataset_id: nil,
            cron: nil,
            extract: nil,
            transform: nil,
            load: []
end

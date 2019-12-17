defmodule Definition.Dataset do
  use Definition, schema: Definition.Schema.Dataset.V1

  defstruct version: nil,
            id: nil,
            owner_id: nil,
            title: nil,
            description: "",
            keywords: [],
            license: nil,
            created_ts: nil,
            profile: %{
              updated_ts: "",
              profiled_ts: "",
              modified_ts: "",
              spatial: [],
              temporal: []
            }
end

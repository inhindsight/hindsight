defmodule Dataset do
  @moduledoc """
  Defines the structure of a dataset within Hindsight.

  Datasets track the metadata attached to a collection of data
  including the source, contact information for the source, a
  description and keywords for catagorizing and discoverability,
  and a profile of updates to the data and its metadata, as well
  as relevant temporal or spatial boundaries represented by the data.

  The "updated_ts" records the last data/time the data was
  amended. The "modified_meta_ts" reflects the last time the
  metadata in the dataset definition was changed.

  # Examples

    iex> Dataset.new(
    ...>              version: 1,
    ...>              id: "123-456",
    ...>              owner_id: "456-789",
    ...>              title: "Cool data",
    ...>              description: "The coolest data",
    ...>              keywords: ["cool", "awesome", "inspirational"],
    ...>              license: "GPL",
    ...>              created_ts: "2020-01-20 18:05:00Z",
    ...>              profile: %{
    ...>                updated_ts: "2020-01-20 18:05:00Z",
    ...>                profiled_ts: "2020-01-20 18:05:00Z",
    ...>                modified_meta_ts: "",
    ...>                spatial: [],
    ...>                temporal: ["2020-01-01 00:00:00Z", "2020-01-15 12:00:00Z"]
    ...>              }
    ...>            )
    {:ok,
      %Dataset{
                version: 1,
                id: "123-456",
                owner_id: "456-789",
                title: "Cool data",
                description: "The coolest data",
                keywords: ["cool", "awesome", "inspirational"],
                license: "GPL",
                created_ts: "2020-01-20 18:05:00Z",
                profile: %{
                  updated_ts: "2020-01-20 18:05:00Z",
                  profiled_ts: "2020-01-20 18:05:00Z",
                  modified_meta_ts: "",
                  spatial: [],
                  temporal: ["2020-01-01 00:00:00Z", "2020-01-15 12:00:00Z"]
                }
              }
    }
  """
  use Definition, schema: Dataset.V1

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
              modified_meta_ts: "",
              spatial: [],
              temporal: []
            }
end

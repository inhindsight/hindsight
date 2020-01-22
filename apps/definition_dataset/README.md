# Dataset

Dataset defines the structure of datasets (all data messages in a
logical group) within Hindsight. Dataset inherits the schema validation
as well as the struct instance creation and lifecycle management functions
from the root Definition library.

```
    Definition
        |_ Dataset
```

The dataset definition collects the information about the source of the
data (including contact information), a usage license, and profile information
for discoverability, and any relevant temporal or spatial boundaries to the data.

## Usage

```elixir
  iex> Dataset.new(
                    version: 1,
                    id: "123-456",
                    owner_id: "456-789"
                    name: "Cool Data",
                    description: "This data is the coolest",
                    keywords: ["awesome", "fun", "inspirational"],
                    license: "GPL",
                    created_ts: "2020-01-20 18:05:00Z",
                    profile: %{
                      updated_ts: "2020-01-20 18:05:00Z",
                      profiled_ts: "2020-01-20 18:05:00Z",
                      modified_meta_ts: "2020-01-20 18:05:00Z",
                      spatial: [],
                      temporal: [2020-01-01, 2020-01-15]
                    }
                  )

  {:ok, %Dataset{ ... same as above ... }}
```

## Installation

```elixir
def deps do
  [
    {:definition_dataset, in_umbrella: true}
  ]
end
```

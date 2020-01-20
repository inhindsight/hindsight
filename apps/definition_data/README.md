# Data

Data is a library for defining the structure of data messages
within the Hindsight ingestion pipeline. Definition Data
inherits the schema validation as well as the struct instance
creation and lifecycle management functions from the root Definition
library.

```
    Definition
        |_ Definition.Data
```

## Usage

```elixir
  iex> Data.new(
            version: 1,
            dataset_id: "123-456",
            extract_id: "567-890",
            payload: %{hello: "world"}
          )

  {:ok, %Data{dataset_id: "123-456", extract_id: "567-890", payload: %{hello: "world"}, version: 1}}
```

## Installation

```elixir
def deps do
  [
    {:definition_data, in_umbrella: true}
  ]
end
```

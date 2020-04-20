# DefinitionLoad

Defines an event struct for loading (`L` in `ETL`) data from a
[source](../protocol_source/README.md) to a [destination](../protocol_destination/README.md).

## Usage

Decide on a source and destination, then define a load.

```elixir
{:ok, load} =
  Load.new(
    id: "some-id",
    dataset_id: "dataset-identifier",
    subset_id: "subset-identifier",
    source: source,
    destination: destination
  )
```

## Installation

```elixir
def deps do
  [
    {:definition_load, in_umbrella: true}
  ]
end
```

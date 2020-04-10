# DefinitionPresto

Defines a `Presto.Table` struct and implements
[destination](../protocol_destination/README.md) protocol for it, allowing
services to write data to Presto in an abstract way.

## Usage

Create a Presto table struct with its 'new/1' function:

```elixir
{:ok, table} = Presto.Table.new(url: "localhost:8080", name: "table_name")
```

## Installation

```elixir
def deps do
  [
    {:definition_presto, in_umbrella: true}
  ]
end
```

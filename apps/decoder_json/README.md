# ExtractDecodeJson

Implementation of the [decoder](../protocol_decoder/README.md) protocol for JSON 
and JSON Lines data.

## Usage

Create a new object with `new/1` ans pass it to another struct requiring a `Decoder` impl.

```elixir
{:ok, json_decoder} = Decoder.Json.new([chunk_size: 1_000])
{:ok, extract} = Extract.new(decoder: json_decoder, ... )
```

```elixir
{:ok, json_lines_decoder} = Decoder.JsonLines.new([])
{:ok, extract} = Extract.new(decoder: json_lines_decoder, ... )
```

## Installation

```elixir
def deps do
  [
    {:decoder_json, in_umbrella: true}
  ]
end
```

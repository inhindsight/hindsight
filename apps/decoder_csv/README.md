# ExtractDecodeCsv

Implementation of the [decoder](../protocol_decoder/README.md) protocol for CSV data.

## Usage


Create a new object with `new/1` and pass it to another struct requiring a `Decoder` impl.

```elixir
{:ok, csv_decoder} = Decoder.Csv.new(headers: ["a", "b"], skip_first_line: true)
{:ok, extract} = Extract.new(decoder: csv_decoder, ...)
```

## Installation

```elixir
def deps do
  [
    {:decoder_csv, in_umbrella: true}
  ]
end
```

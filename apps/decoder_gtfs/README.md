# DecoderGtfs

Implementation of the [decoder](../protocol_decoder/README.md) protocol for [GTFS](http://gtfs.org) data.

**NOTE**: This decodes GTFS realtime data using [this](lib/gtfs-realtime.pb.ex) protobuf parser. It will not work for static GTFS data.

## Usage

Create a new object with `new/1` and pass it to another struct requiring a `Decoder` impl. `chunk_size` can optionally be configured via `new/1`. It defaults to 100.

```elixir
{:ok, gtfs_decoder} = Decoder.Gtfs.new(chunk_size: 42)
{:ok, extract} = Extract.new(decoder: gtfs_decoder, ...)
```

## Installation

```elixir
def deps do
  [
    {:decoder_gtfs, in_umbrella: true}
  ]
end
```

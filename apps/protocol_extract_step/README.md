# ProtocolExtractStep

Defines a protocol for extracting data from any generic source. This app also
includes modules for wrapping those extractions in context and enveloping data
as it is extracted.

## Usage

### Protocol

A step must implement an `execute/2` function to be a part of the data extraction
pipeline.

See [Http.Get](../extract_http/lib/extract/http/get.ex) as an example.

### Context in the extraction pipeline

The extraction process is one big reduce, and its accumulator is an instance of
the `Extract.Context` struct. See the [moduledoc](lib/extract/context.ex) for
more info.

### Message

The `Extract.Message` struct acts as an envelope for data in the extraction pipeline and
includes metadata for the extraction process.

See [Extract.Http.Get.stream_from_file/2](../extract_http/lib/extract/http/get.ex) as an example.

The `Extract.Context` struct is the extraction pipeline's accumulator.


## Installation

```elixir
def deps do
  [
    {:protocol_extract_step, in_umbrella: true}
  ]
end
```

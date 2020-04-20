# DefinitionChannel

Defines a `Channel.Topic` struct and implements the 
 protocol for writing
to a WebSocket.

Defines an implementation of the [destination](../protocol_destination/README.md)
protcol for writing data to a WebSocket via 
[Phoenix.Channel](https://hexdocs.pm/phoenix/channels.html).

## Usage

Create a channel topic struct with its `new/1` function:

```elixir
{:ok, topic} = Channel.Topic.new(name: "topic-name")
```

Messages can be cached on a per-topic basis. By default, the cache is turned off.
Pass an integer (>0) to the cache field during `new/1` to toggle cache on for that 
many messages.

```elixir
{:ok, topic} =
  Channel.Topic.new(
    name: "topic-name",
    cache: 1_000
  )
```

### Writing

With most `Destination.t()` impls, you'd write via the implementation's
`write/3` function. But data must be written to an application-specific
`Phoenix.Endpoint` when it comes to Phoenix channels. So using this
impl's `write/3` will result in an exception.

Instead, use the application specific `Phoenix.Endpoint` to write.
An example:

```elixir
BroadcastWeb.Endpoint.broadcast!("broadcast:#{topic.name}", "update", data)
```

## Installation

```elixir
def deps do
  [
    {:definition_channel, in_umbrella: true}
  ]
end
```

# AcceptWebsocket

Implementation of the [connection](../definition_accept/lib/accept/connection.ex) protocol for data pushed over a WebSocket.

## Usage

Create a new object with `new/1`.

```elixir
{:ok, ws} = Accept.Websocket.new(path: "foo/bar/", port: 9001)
```

## Installation

```elixir
def deps do
  [
    {:accept_websocket, in_umbrella: true}
  ]
end
```

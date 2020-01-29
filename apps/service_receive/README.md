# Receive

Receive is Hindsight's push gateway, managing processes that listen
at the edge of the system on a specified socket for incoming messages from
a data source and pushing them into the system via topic.

## Installation

```elixir
def deps do
  [
    {:service_receive_udp, in_umbrella: true}
  ]
end
```

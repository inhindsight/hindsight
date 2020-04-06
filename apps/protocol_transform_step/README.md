# ProtocolTransformStep

Defines a protocol for transforming fields in a [dictionary](../definition_dictionary/README.md).

## Usage

A step must implement this protocol to be used in transformations by Hindsight services.
Implementing this protocol requires two functions: `transform_dictionary/2` and `create_function/2`.

See [Transform.DeleteField](../transformer/lib/transform/delete_field.ex) as an example.

## Installation

```elixir
def deps do
  [
    {:protocol_transform_step, in_umbrella: true}
  ]
end
```

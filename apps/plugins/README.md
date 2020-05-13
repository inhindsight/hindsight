# Plugins

This app provides a single function meant to find and load custom protocol implementations. The
function should be used on application startup.

``` elixir
# application.ex
def start(_, _) do
  Plugins.load!()
  
  # ...
end
```

Plugin files in a top-level `plugins` directory will be compiled and loaded into that application.
Plugins must end in `.ex`. They can be nested in subdirectories. The glob for finding plugins is
`plugins/**/*.ex`.

Plugins that don't compile will raise exceptions and blow up the dependent application. This
is the intended design.

## Docker

The Hindsight [Dockerfile](../../Dockerfile) creates a plugins directory for this purpose.
Any plugin copied into this directory will be made available to all standard Hindsight services.

You will have to build your own image from the official Hindsight image.

```dockerfile
FROM inhindsight/hindsight:latest
COPY my_plugins/ plugins/
```

You will also need to specify your `image.repository` and `image.tag` when using `helm`.

## Installation

```elixir
def deps do
  [
    {:plugins, in_umbrella: true}
  ]
end
```

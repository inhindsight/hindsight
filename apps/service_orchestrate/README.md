# Orchestrate

Service for orchestrating scheduled events within Hindsight. Any cadenced event will
be published from `Orchestrate`.

## Release

Run `mix release orchestrate` to build an Erlang release for this service.

## Docker

The latest release is baked into the `inhindsight/hindsight:latest` Docker image
and is started with a `orchestrate/bin/orchestrate start` command.

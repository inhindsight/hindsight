# Profile

Service for profiling data in the ingestion pipeline. Metadata is collected for
geospatial and temporal boundaries. The list of metadata collected may grow over time.

## Release

Run `mix release profile` to build an Erlang release for this service.

## Docker

The latest release is baked into the `inhindsight/hindsight:latest` Docker image
and is started with a `profile/bin/profile start` command.

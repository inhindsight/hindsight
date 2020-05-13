# PlatformRunner

Hindsight in its entirety, runnable locally.

## Usage

You can run Hindsight locally by running `platform_runner`.

Spin up external dependencies with [Divo](https://hex.pm/packages/divo) and drop
into an IEx session.

```bash
MIX_ENV=integration mix docker.start
MIX_ENV=integration iex -S mix
```

## E2E tests

Hindsight's end-to-end tests are defined in `platform_runner`. You can use the
umbrella-level mix alias (`mix test.e2e`) or run them directly out of `platform_runner`.

```bash
MIX_ENV=integration mix docker.start
MIX_ENV=integration mix test
```

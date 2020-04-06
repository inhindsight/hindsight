# MetricsReporter

The MetricsReporter creates a configurable
instance of the Prometheus Telemetry Metrics
Reporter for exposing application telemetry events
as metrics on a `/metrics` endpoint for scraping 
by a Prometheus server.

Create an instance of the MetricsReporter by
including the `use MetricsReporter` macro in a
module within an application and include the
custom module in your application supervision tree.

The MetricsReporter comes with Erlang VM metrics
reported by default but you can customize the metrics
exported by a given instance of MetricsReporter by
overriding the `metrics/0` function in the module to
return a list of the desired metrics.

When overriding the default `metrics/0` function, in
order to include the Erlang VM metrics provided by the
`:telemetry_poller` library you will either need to re-list
the desired metrics a la carte or include the call to
the default implmentation within your function with the
`super/0` function:

```elixir
  def metrics() do
    super() ++
      [
        counter("other.metrics")
        last_value("still.more.metrics")
      ]
  end
```

## Installation

```elixir
def deps do
  [
    {:metrics_reporter, in_umbrella: true}
  ]
end
```

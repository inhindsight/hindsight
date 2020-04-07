defmodule MetricsReporter.Packages do
  @moduledoc """
  Pre-define commonly associated bundles of Telemetry Metrics
  definitions for easy inclusion in the MetricsReporter `metrics/0`
  function when configuring an instance of MetricsReporter.
  """
  import Telemetry.Metrics

  def kafka_metrics() do
    [
      counter("destination.kafka.write.count")
    ]
  end

  def phoenix_metrics() do
    [
      last_value("phoenix.endpoint.start.time"),
      last_value("phoenix.router.dispatch.start"),
      last_value(
        "phoenix.endpoint.stop.duration.seconds",
        event_name: [:phoenix, :endpoint, :stop],
        measurement: :duration,
        unit: {:native, :second}
      ),
      last_value(
        "phoenix.router_dispatch.stop.duration.seconds",
        event_name: [:phoenix, :router_dispatch, :stop],
        measurement: :duration,
        unit: {:native, :second}
      ),
      last_value(
        "phoenix.socket_connected.duration.seconds",
        event_name: [:phoenix, :socket_connected],
        measurement: :duration,
        unit: {:native, :second}
      ),
      last_value(
        "phoenix.channel_joined.duration.seconds",
        event_name: [:phoenix, :channel_joined],
        measurement: :duration,
        unit: {:native, :second}
      ),
      last_value(
        "phoenix.channel_handled_in.duration.seconds",
        event_name: [:phoenix, :channel_handled_in],
        measurement: :duration,
        unit: {:native, :second}
      )
    ]
  end
end

defmodule Acquire.MetricsReporter do
  use MetricsReporter, name: :acquire_metrics, port: 9568

  @impl MetricsReporter
  def metrics() do
    super() ++
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

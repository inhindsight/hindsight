defmodule Acquire.MetricsReporter do
  use MetricsReporter, name: :acquire_metrics

  @impl MetricsReporter
  def metrics() do
    super() ++
      [
        last_value("phoenix.endpoint.start.time"),
        last_value("phoenix.router.dispatch.start"),
        summary("phoenix.endpoint.stop.duration", unit: {:native, :millisecond}),
        summary("phoenix.router_dispatch.stop.duration", unit: {:native, :millisecond}),
        summary("phoenix.socket_connected.duration", unit: {:native, :millisecond}),
        summary("phoenix.channel_joined.duration", unit: {:native, :millisecond}),
        summary("phoenix.channel_handled_in.duration", unit: {:native, :millisecond})
      ]
  end
end

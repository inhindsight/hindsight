defmodule Gather.MetricsReporter do
  use Properties, otp_app: :service_gather
  getter(:port, default: 9568)
  use MetricsReporter, name: :gather_metrics, port: port()

  @impl MetricsReporter
  def metrics() do
    super() ++ kafka_metrics()
  end
end

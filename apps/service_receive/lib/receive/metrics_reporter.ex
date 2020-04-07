defmodule Receive.MetricsReporter do
  use Properties, otp_app: :service_receive
  getter(:port, default: 9568)
  use MetricsReporter, name: :receive_metrics, port: port()

  @impl MetricsReporter
  def metrics() do
    super() ++ kafka_metrics()
  end
end

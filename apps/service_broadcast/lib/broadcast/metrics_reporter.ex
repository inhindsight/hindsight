defmodule Broadcast.MetricsReporter do
  @moduledoc """
  Extension of `MetricsReporter` for scraping `Broadcast` metrics.
  """
  use Properties, otp_app: :service_broadcast
  getter(:port, default: 9568)
  use MetricsReporter, name: :broadcast_metrics, port: port()

  @impl MetricsReporter
  def metrics() do
    super() ++ phoenix_metrics()
  end
end

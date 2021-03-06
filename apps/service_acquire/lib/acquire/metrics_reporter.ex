defmodule Acquire.MetricsReporter do
  @moduledoc """
  Extension of `MetricsReporter` for scraping `Acquire` metrics.
  """
  use Properties, otp_app: :service_acquire
  getter(:port, default: 9568)
  use MetricsReporter, name: :acquire_metrics, port: port()

  @impl MetricsReporter
  def metrics() do
    super() ++ phoenix_metrics()
  end
end

defmodule Orchestrate.MetricsReporter do
  @moduledoc """
  Extension of `MetricsReporter` for scraping `Orchestrate` metrics.
  """
  use Properties, otp_app: :service_orchestrate
  getter(:port, default: 9568)
  use MetricsReporter, name: :orchestrate_metrics, port: port()
end

defmodule Aggregate.MetricsReporter do
  @moduledoc """
  Extension of `MetricsReporter` for scraping `Aggregate` metrics.
  """
  use Properties, otp_app: :service_aggregate
  getter(:port, default: 9568)
  use MetricsReporter, name: :aggregate_metrics, port: port()
end

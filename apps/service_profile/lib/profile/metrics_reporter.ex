defmodule Profile.MetricsReporter do
  @moduledoc """
  Extension of `MetricsReporter` for scraping `Profile` metrics.
  """
  use Properties, otp_app: :service_profile
  getter(:port, default: 9568)
  use MetricsReporter, name: :profile_metrics, port: port()
end

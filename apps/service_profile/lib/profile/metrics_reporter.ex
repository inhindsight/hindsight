defmodule Profile.MetricsReporter do
  use Properties, otp_app: :service_profile
  getter(:port, default: 9568)
  use MetricsReporter, name: :profile_metrics, port: port()
end

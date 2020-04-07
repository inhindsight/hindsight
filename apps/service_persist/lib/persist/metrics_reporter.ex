defmodule Persist.MetricsReporter do
  use Properties, otp_app: :service_persist
  getter(:port, default: 9568)
  use MetricsReporter, name: :persist_metrics, port: port()
end

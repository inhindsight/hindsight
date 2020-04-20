defmodule Orchestrate.Scheduler do
  @moduledoc """
  See [Quantum](https://hexdocs.pm/quantum/configuration.html).
  """
  use Quantum.Scheduler, otp_app: :service_orchestrate
end

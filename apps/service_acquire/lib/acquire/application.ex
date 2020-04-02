defmodule Acquire.Application do
  @moduledoc false

  use Application
  use Properties, otp_app: :service_acquire

  getter(:brook, required: true)

  def instance(), do: :acquire_instance

  def start(_type, _args) do
    children = [
      Acquire.MetricsReporter,
      start_brook(),
      AcquireWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Acquire.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp start_brook() do
    {Brook, Keyword.put(brook(), :instance, instance())}
  end

  def config_change(changed, _new, removed) do
    AcquireWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

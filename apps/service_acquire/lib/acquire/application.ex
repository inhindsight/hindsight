defmodule Acquire.Application do
  @moduledoc false

  use Application
  use Properties, otp_app: :service_acquire

  def instance, do: :acquire_instance

  def start(_type, _args) do
    Plugins.load!()

    children = [
      Acquire.MetricsReporter,
      brook(),
      AcquireWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Acquire.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    AcquireWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp brook do
    case get_config_value(:brook) do
      nil -> {Brook, Initializer.Brook.config(instance(), "acquire", Acquire.Event.Handler)}
      config -> {Brook, Keyword.put(config, :instance, instance())}
    end
  end
end

defmodule Persist.Application do
  @moduledoc false

  use Application
  use Properties, otp_app: :service_persist

  def instance, do: :persist_instance

  def start(_type, _args) do
    Plugins.load!()

    children =
      [
        Persist.Load.Registry,
        Persist.Load.Supervisor,
        Persist.Compact.Registry,
        Persist.Compact.Supervisor,
        Persist.MetricsReporter,
        brook(),
        init()
      ]
      |> List.flatten()

    opts = [strategy: :one_for_one, name: Persist.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp init do
    case get_config_value(:init?, default: true) do
      true -> Persist.Init
      false -> []
    end
  end

  defp brook do
    case get_config_value(:brook) do
      nil -> {Brook, Initializer.Brook.config(instance(), "persist", Persist.Event.Handler)}
      config -> {Brook, Keyword.put(config, :instance, instance())}
    end
  end
end

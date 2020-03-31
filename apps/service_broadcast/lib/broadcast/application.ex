defmodule Broadcast.Application do
  @moduledoc false

  use Application
  use Properties, otp_app: :service_broadcast

  def instance(), do: :broadcast_instance

  def start(_type, _args) do
    children =
      [
        Broadcast.Cache.Registry,
        Broadcast.Stream.Registry,
        Broadcast.Stream.Supervisor,
        Broadcast.MetricsReporter,
        BroadcastWeb.Endpoint,
        dlq(),
        brook(),
        init()
      ]
      |> List.flatten()

    opts = [strategy: :one_for_one, name: Broadcast.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp init() do
    case get_config_value(:init?, default: true) do
      true -> Broadcast.Init
      false -> []
    end
  end

  defp dlq() do
    case get_config_value(:kafka_endpoints) do
      nil -> []
      endpoints -> {Broadcast.DLQ, endpoints: endpoints}
    end
  end

  defp brook() do
    case get_config_value(:brook) do
      nil -> []
      config -> {Brook, Keyword.put(config, :instance, instance())}
    end
  end

  def config_change(changed, _new, removed) do
    BroadcastWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

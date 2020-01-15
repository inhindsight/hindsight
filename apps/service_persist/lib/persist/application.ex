defmodule Persist.Application do
  @moduledoc false

  use Application
  use Properties, otp_app: :service_persist

  def instance(), do: :persist_instance

  def start(_type, _args) do
    children =
      [
        Persist.Load.Registry,
        Persist.Load.Supervisor,
        dlq(),
        brook(),
        init()
      ]
      |> List.flatten()

    opts = [strategy: :one_for_one, name: Persist.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp init() do
    case get_config_value(:init?, default: true) do
      true -> Persist.Init
      false -> []
    end
  end

  defp dlq() do
    case Application.get_env(:service_persist, :kafka_endpoints) do
      nil -> []
      endpoints -> {Persist.DLQ, endpoints: endpoints}
    end
  end

  defp brook() do
    case get_config_value(:brook, required: true) do
      nil -> []
      config -> {Brook, Keyword.put(config, :instance, instance())}
    end
  end
end

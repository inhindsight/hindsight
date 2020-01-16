defmodule Gather.Application do
  @moduledoc false

  use Application
  use Properties, otp_app: :service_gather

  def instance(), do: :gather_instance

  def start(_type, _args) do
    children =
      [
        Gather.Extraction.Supervisor,
        dlq(),
        brook(),
        init()
      ]
      |> List.flatten()

    opts = [strategy: :one_for_one, name: Gather.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp init() do
    case get_config_value(:init?, default: true) do
      true -> Gather.Init
      false -> []
    end
  end

  defp dlq() do
    case get_config_value(:kafka_endpoints) do
      nil -> []
      endpoints -> {Gather.DLQ, endpoints: endpoints}
    end
  end

  defp brook() do
    case get_config_value(:brook, required: true) do
      nil -> []
      config -> {Brook, Keyword.put(config, :instance, instance())}
    end
  end
end

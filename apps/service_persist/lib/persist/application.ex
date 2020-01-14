defmodule Persist.Application do
  @moduledoc false

  use Application

  @config Application.get_env(:service_persist, __MODULE__, [])

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
    case Keyword.get(@config, :init?, true) do
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
    case Application.get_env(:service_persist, :brook) do
      nil -> []
      config -> {Brook, Keyword.put(config, :instance, instance())}
    end
  end
end

defmodule Gather.Application do
  @moduledoc false

  use Application

  @config Application.get_env(:service_gather, __MODULE__, [])
  @init? Keyword.get(@config, :init?, true)

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
    case @init? do
      true -> Gather.Init
      false -> []
    end
  end

  defp dlq() do
    case Application.get_env(:service_gather, :kafka_endpoints) do
      nil -> []
      endpoints -> {Gather.DLQ, endpoints: endpoints}
    end
  end

  defp brook() do
    case Application.get_env(:service_gather, :brook) do
      nil -> []
      config -> {Brook, Keyword.put(config, :instance, instance())}
    end
  end
end

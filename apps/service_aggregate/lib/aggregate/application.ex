defmodule Aggregate.Application do
  @moduledoc false

  use Application
  use Properties, otp_app: :service_aggregate

  def instance(), do: :aggregate_instance

  def start(_type, _args) do
    Plugins.load!()

    children =
      [
        Aggregate.Feed.Registry,
        Aggregate.Feed.Supervisor,
        Aggregate.MetricsReporter,
        brook(),
        init()
      ]
      |> List.flatten()

    opts = [strategy: :one_for_one, name: Aggregate.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp init() do
    case get_config_value(:init?, default: true) do
      true -> Aggregate.Init
      false -> []
    end
  end

  defp brook() do
    case get_config_value(:brook, required: true) do
      nil -> []
      config -> {Brook, Keyword.put(config, :instance, instance())}
    end
  end
end

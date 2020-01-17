defmodule Orchestrate.Application do
  @moduledoc false

  use Application
  use Properties, otp_app: :service_orchestrate

  def instance(), do: :orchestrate_instance

  def start(_type, _args) do
    children =
      [
        Orchestrate.Scheduler,
        brook()
      ]
      |> List.flatten()

    opts = [strategy: :one_for_one, name: Orchestrate.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp brook() do
    case get_config_value(:brook, required: true) do
      nil -> []
      config -> {Brook, Keyword.put(config, :instance, instance())}
    end
  end
end

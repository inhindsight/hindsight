defmodule Receive.Application do
  @moduledoc false

  use Application
  use Properties, otp_app: :service_receive

  def instance(), do: :receive_instance

  def start(_type, _args) do
    children =
      [
        Receive.Accept.Registry,
        Receive.Accept.Supervisor,
        brook(),
        init()
      ]
      |> List.flatten()

    opts = [strategy: :one_for_one, name: Receive.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp init() do
    if get_config_value(:init?, default: true), do: Receive.Init, else: []
  end

  defp brook() do
    case get_config_value(:brook, required: true) do
      nil -> []
      config -> {Brook, Keyword.put(config, :instance, instance())}
    end
  end
end

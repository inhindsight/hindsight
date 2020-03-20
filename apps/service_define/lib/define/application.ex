defmodule Define.Application do
  use Application
  use Properties, otp_app: :service_define

  def instance(), do: :define_instance

  def start(_type, _args) do
    children = [
      DefineWeb.Endpoint,
      brook()
    ]

    opts = [strategy: :one_for_one, name: Define.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    DefineWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp brook() do
    case get_config_value(:brook, required: true) do
      nil -> []
      config -> {Brook, Keyword.put(config, :instance, instance())}
    end
  end
end

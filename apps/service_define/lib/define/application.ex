defmodule Define.Application do
  use Application
  use Properties, otp_app: :service_define

  getter(:brook, required: true)

  def instance(), do: :define_instance

  def start(_type, _args) do
    children = [
      start_brook(),
      Define.MetricsReporter,
      DefineWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Define.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp start_brook() do
    {Brook, Keyword.put(brook(), :instance, instance())}
  end

  def config_change(changed, _new, removed) do
    DefineWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

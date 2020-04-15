defmodule Define.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    children = [
      Define.MetricsReporter,
      DefineWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Define.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    DefineWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

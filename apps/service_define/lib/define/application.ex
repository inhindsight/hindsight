defmodule Define.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  use Properties, otp_app: :service_define

  def instance(), do: :define_instance

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Start the endpoint when the application starts
      DefineWeb.Endpoint,
      brook()

      # Starts a worker by calling: Define.Worker.start_link(arg)
      # {Define.Worker, arg},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Define.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
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

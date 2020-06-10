defmodule AcceptWebsocket.MixProject do
  use Mix.Project

  def project do
    [
      app: :accept_websocket,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:definition, in_umbrella: true},
      {:definition_accept, in_umbrella: true},
      {:plug_cowboy, "~> 2.1.0"},
      {:json_serde, "~> 1.0"},
      {:credo, "~> 1.3", only: [:dev]},
      {:dialyxir, "~> 1.0.0-rc.7", only: [:dev], runtime: false},
      {:testing, in_umbrella: true, only: [:test]}
    ]
  end
end

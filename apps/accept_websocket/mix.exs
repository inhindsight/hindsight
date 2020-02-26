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
      # Remove this override when gun releases a 2.0+ vs. to hex using cowlib 2.8
      {:cowlib, "~> 2.8.0", override: true},
      {:definition, in_umbrella: true},
      {:definition_accept, in_umbrella: true},
      {:plug_cowboy, "~> 2.1.0"},
      {:brook_serializer, "~> 2.2", only: [:test]},
      {:dialyxir, "~> 1.0.0-rc.7", only: [:dev], runtime: false},
      {:testing, in_umbrella: true, only: [:test]}
    ]
  end
end

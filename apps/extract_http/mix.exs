defmodule ExtractHttp.MixProject do
  use Mix.Project

  def project do
    [
      app: :extract_http,
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
      {:extract, in_umbrella: true},
      {:tesla, github: "teamon/tesla", branch: "master"},
      {:mint, "~> 1.0", override: true},
      {:castore, "~> 0.1.4"},
      {:dialyxir, "~> 1.0.0-rc.7", only: [:dev], runtime: false},
      {:bypass, "~> 1.0", only: [:test]}
    ]
  end
end

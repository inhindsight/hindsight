defmodule Extract.MixProject do
  use Mix.Project

  def project do
    [
      app: :definition_extract,
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
      {:dialyxir, "~> 1.0.0-rc.7", only: [:dev], runtime: false},
      {:ok, in_umbrella: true, only: [:test]},
      {:checkov, "~> 1.0", only: [:dev, :test]}
    ]
  end
end

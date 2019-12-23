defmodule Data.MixProject do
  use Mix.Project

  def project do
    [
      app: :definition_data,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:definition, in_umbrella: true},
      {:dialyxir, "~> 1.0.0-rc.6", only: [:dev], runtime: false},
      {:definition_faker, in_umbrella: true, only: [:dev, :test]},
      {:checkov, "~> 1.0", only: [:dev, :test]},
      {:ok, in_umbrella: true, only: [:test]}
    ]
  end
end

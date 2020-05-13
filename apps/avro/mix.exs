defmodule Avro.MixProject do
  use Mix.Project

  def project do
    [
      app: :avro,
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

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:erlavro, "~> 2.8"},
      {:ok, in_umbrella: true},
      {:definition_dictionary, in_umbrella: true},
      {:temp, "~> 0.4.7"},
      {:checkov, "~> 1.0", only: [:dev, :test]},
      {:credo, "~> 1.3", only: [:dev]},
      {:placebo, "~> 2.0.0-rc.2", only: [:dev, :test]}
    ]
  end
end

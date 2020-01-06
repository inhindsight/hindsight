defmodule WriterPresto.MixProject do
  use Mix.Project

  def project do
    [
      app: :writer_presto,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      consolidate_protocols: Mix.env() != :test
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:writer, in_umbrella: true},
      {:definition_dictionary, in_umbrella: true},
      {:prestige, "~> 1.0"},
      {:tesla, github: "teamon/tesla", branch: "master", override: true},
      {:divo, "~> 1.1", only: [:dev, :test]},
      {:checkov, "~> 1.0", only: [:dev, :test]},
      {:placebo, "~> 2.0.0-rc.2", only: [:dev, :test]}
    ]
  end
end

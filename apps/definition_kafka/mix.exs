defmodule DefinitionKafka.MixProject do
  use Mix.Project

  def project do
    [
      app: :definition_kafka,
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
      {:elsa, "~> 0.12", override: true},
      {:ok, in_umbrella: true},
      {:protocol_destination, in_umbrella: true},
      {:checkov, "~> 1.0", only: [:dev, :test]},
      {:divo, "~> 1.1", only: [:dev, :test]},
      {:divo_kafka, "~> 0.1.6", only: [:test]},
      {:testing, in_umbrella: true, only: [:test]}
    ]
  end
end

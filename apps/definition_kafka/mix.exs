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
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:annotated_retry, in_umbrella: true},
      {:dlq, in_umbrella: true},
      {:elsa, "~> 0.12", override: true},
      {:jason, "~> 1.1"},
      {:ok, in_umbrella: true},
      {:protocol_destination, in_umbrella: true},
      {:protocol_source, in_umbrella: true},
      {:telemetry, "~> 0.4.1"},
      {:credo, "~> 1.3", only: [:dev]},
      {:divo, "~> 1.1", only: [:dev, :test]},
      {:divo_kafka, "~> 0.1.6", only: [:test]},
      {:mox, "~> 0.5.1", only: [:test]},
      {:placebo, "~> 2.0.0-rc2", only: [:dev, :test]},
      {:testing, in_umbrella: true, only: [:test]}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end

defmodule Kafka.Subscribe.MixProject do
  use Mix.Project

  def project do
    [
      app: :extract_kafka,
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
      {:elsa, "~> 0.11.1"},
      {:ok, in_umbrella: true},
      {:extract_step, in_umbrella: true},
      {:brook_serializer, "~> 2.2"},
      {:divo, "~> 1.1", only: [:dev, :test]},
      {:divo_kafka, "~> 0.1.6", only: [:test]},
      {:testing, in_umbrella: true, only: [:test]},
      {:checkov, "~> 1.0", only: [:dev, :test]}
    ]
  end
end

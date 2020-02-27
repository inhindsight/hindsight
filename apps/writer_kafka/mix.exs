defmodule WriterKafka.MixProject do
  use Mix.Project

  def project do
    [
      app: :writer_kafka,
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
      {:writer, in_umbrella: true},
      {:elsa, git: "https://github.com/bbalser/elsa", override: true},
      {:retry, "~> 0.13.0"},
      {:ok, in_umbrella: true},
      {:telemetry, "~> 0.4.1"},
      {:testing, in_umbrella: true, only: [:test]},
      {:divo, "~> 1.1", only: [:dev, :test]},
      {:divo_kafka, "~> 0.1.6", only: [:test]},
      {:placebo, "~> 2.0.0-rc.2", only: [:dev, :test]}
    ]
  end
end

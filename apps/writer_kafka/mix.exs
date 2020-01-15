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
      {:elsa, "~> 0.11.1"},
      {:retry, "~> 0.13.0"},
      {:ok, in_umbrella: true},
      {:testing, in_umbrella: true, only: [:test]},
      {:divo, "~> 1.1", only: [:dev, :test]},
      {:divo_kafka, "~> 0.1.6", only: [:test]}
    ]
  end
end

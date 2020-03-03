defmodule WriterDlq.MixProject do
  use Mix.Project

  def project do
    [
      app: :writer_dlq,
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
      {:definition, in_umbrella: true},
      {:elsa, "~> 0.12", override: true},
      {:writer, in_umbrella: true},
      {:writer_kafka, in_umbrella: true},
      {:properties, in_umbrella: true},
      {:mox, "~> 0.5.1", only: [:test]},
      {:checkov, "~> 1.0", only: [:test]},
      {:testing, in_umbrella: true, only: [:test]}
    ]
  end

  defp elixirc_paths(:test), do: ["test/support", "lib"]
  defp elixirc_paths(_), do: ["lib"]
end

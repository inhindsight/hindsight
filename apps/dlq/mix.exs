defmodule Dlq.MixProject do
  use Mix.Project

  def project do
    [
      app: :dlq,
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
      extra_applications: [:logger],
      mod: {Dlq.Application, []}
    ]
  end

  defp deps do
    [
      {:annotated_retry, in_umbrella: true},
      {:elsa, "~> 0.12"},
      {:jason, "~> 1.1"},
      {:placebo, "~> 2.0.0-rc.2", only: [:dev, :test]},
      {:properties, in_umbrella: true},
      {:testing, in_umbrella: true, only: [:test]}
    ]
  end
end

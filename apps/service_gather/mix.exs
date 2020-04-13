defmodule Gather.MixProject do
  use Mix.Project

  def project do
    [
      app: :service_gather,
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
      extra_applications: [:logger],
      mod: {Gather.Application, []}
    ]
  end

  defp deps do
    [
      {:annotated_retry, in_umbrella: true},
      {:brook, "~> 0.5"},
      {:definition_deadletter, in_umbrella: true},
      {:definition_dictionary, in_umbrella: true},
      {:definition_events, in_umbrella: true},
      {:definition_extract, in_umbrella: true},
      {:dlq, in_umbrella: true},
      {:elsa, "~> 0.12", override: true},
      {:extractor, in_umbrella: true},
      {:initializer, in_umbrella: true},
      {:management, in_umbrella: true},
      {:metrics_reporter, in_umbrella: true},
      {:properties, in_umbrella: true},
      {:retry, "~> 0.13.0"},
      {:transformer, in_umbrella: true},
      {:bypass, "~> 1.0", only: [:test]},
      {:credo, "~> 1.3", only: [:dev]},
      {:mox, "~> 0.5.1", only: [:test]},
      {:placebo, "~> 2.0.0-rc2", only: [:dev, :test]},
      {:testing, in_umbrella: true, only: [:test]}
    ]
  end

  defp elixirc_paths(:test), do: ["test/support", "lib"]
  defp elixirc_paths(_), do: ["lib"]
end

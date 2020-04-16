defmodule Profile.MixProject do
  use Mix.Project

  def project do
    [
      app: :service_profile,
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
      mod: {Profile.Application, []}
    ]
  end

  defp deps do
    [
      {:annotated_retry, in_umbrella: true},
      {:brook, "~> 0.5"},
      {:brook_storage_postgres, "~> 0.1.1"},
      {:extractor, in_umbrella: true},
      {:definition_dictionary, in_umbrella: true},
      {:definition_events, in_umbrella: true},
      {:definition_kafka, in_umbrella: true},
      {:flow, "~> 1.0"},
      {:gen_stage, "~> 1.0", override: true},
      {:initializer, in_umbrella: true},
      {:management, in_umbrella: true},
      {:metrics_reporter, in_umbrella: true},
      {:properties, in_umbrella: true},
      {:protocol_source, in_umbrella: true},
      {:checkov, "~> 1.0", only: [:dev, :test]},
      {:credo, "~> 1.3", only: [:dev]},
      {:placebo, "~> 2.0.0-rc.2", only: [:dev, :test]},
      {:testing, in_umbrella: true, only: [:dev, :test]}
    ]
  end

  defp elixirc_paths(:test), do: ["test/support", "lib"]
  defp elixirc_paths(_), do: ["lib"]
end

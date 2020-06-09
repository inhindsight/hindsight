defmodule Orchestrate.MixProject do
  use Mix.Project

  def project do
    [
      app: :service_orchestrate,
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
      mod: {Orchestrate.Application, []}
    ]
  end

  defp deps do
    [
      {:brook, "~> 0.6"},
      {:definition_dictionary, in_umbrella: true},
      {:definition_events, in_umbrella: true},
      {:definition_presto, in_umbrella: true},
      {:elsa, "~> 0.12", override: true},
      {:gen_stage, "~> 1.0", override: true},
      {:extractor, in_umbrella: true},
      {:management, in_umbrella: true},
      {:metrics_reporter, in_umbrella: true},
      {:plugins, in_umbrella: true},
      {:properties, in_umbrella: true},
      {:quantum, "~> 2.3"},
      {:timex, "~> 3.0"},
      {:transformer, in_umbrella: true},
      {:uuid, "~> 1.1"},
      {:credo, "~> 1.3", only: [:dev]},
      {:placebo, "~> 2.0.0-rc.2", only: [:dev, :test]},
      {:testing, in_umbrella: true, only: [:test]}
    ]
  end
end

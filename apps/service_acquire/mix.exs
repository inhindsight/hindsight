defmodule Acquire.MixProject do
  use Mix.Project

  def project do
    [
      app: :service_acquire,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {Acquire.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:corsica, "~> 1.0"},
      {:definition, in_umbrella: true},
      {:definition_dictionary, in_umbrella: true},
      {:definition_events, in_umbrella: true},
      {:definition_presto, in_umbrella: true},
      {:elsa, "~> 0.12", override: true},
      {:extractor, in_umbrella: true},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:management, in_umbrella: true},
      {:metrics_reporter, in_umbrella: true},
      {:nimble_parsec, "~> 0.5.3"},
      {:ok, in_umbrella: true},
      {:phoenix, "~> 1.4.11"},
      {:phoenix_pubsub, "~> 1.1"},
      {:plug_cowboy, "~> 2.0"},
      {:plugins, in_umbrella: true},
      {:prestige, "~> 1.0"},
      {:properties, in_umbrella: true},
      {:transformer, in_umbrella: true},
      {:checkov, "~> 1.0", only: [:dev, :test]},
      {:credo, "~> 1.3", only: [:dev]},
      {:mox, "~> 0.5.1", only: [:test]},
      {:placebo, "~> 2.0.0-rc.2", only: [:dev, :test]},
      {:testing, in_umbrella: true, only: [:test]}
    ]
  end
end

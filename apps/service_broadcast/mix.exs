defmodule Broadcast.MixProject do
  use Mix.Project

  def project do
    [
      app: :service_broadcast,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {Broadcast.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:annotated_retry, in_umbrella: true},
      {:brook, "~> 0.5"},
      {:definition_dictionary, in_umbrella: true},
      {:definition_events, in_umbrella: true},
      {:definition_kafka, in_umbrella: true},
      {:dlq, in_umbrella: true},
      {:elsa, "~> 0.12", override: true},
      {:extractor, in_umbrella: true},
      {:gettext, "~> 0.11"},
      {:initializer, in_umbrella: true},
      {:jason, "~> 1.1"},
      {:management, in_umbrella: true},
      {:phoenix, "~> 1.4.11"},
      {:phoenix_pubsub, "~> 1.1"},
      {:plug_cowboy, "~> 2.0"},
      {:properties, in_umbrella: true},
      {:protocol_source, in_umbrella: true},
      {:transformer, in_umbrella: true},

      # Dev/Test Dependencies
      {:checkov, "~> 1.0", only: [:dev, :test]},
      {:mox, "~> 0.5.1", only: [:test]},
      {:placebo, "~> 2.0.0-rc.2", only: [:dev, :test]},
      {:testing, in_umbrella: true, only: [:test]}
    ]
  end
end

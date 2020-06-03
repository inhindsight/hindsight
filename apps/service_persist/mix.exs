defmodule Persist.MixProject do
  use Mix.Project

  def project do
    [
      app: :service_persist,
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
      mod: {Persist.Application, []}
    ]
  end

  defp deps do
    [
      {:annotated_retry, in_umbrella: true},
      {:avro, in_umbrella: true},
      {:brook, "~> 0.5"},
      {:brook_storage_postgres, "~> 0.1.1"},
      {:definition_dictionary, in_umbrella: true},
      {:definition_events, in_umbrella: true},
      {:definition_kafka, in_umbrella: true},
      {:definition_presto, in_umbrella: true},
      {:dlq, in_umbrella: true},
      {:elsa, "~> 0.12", override: true},
      {:ex_aws_s3, "~> 2.0"},
      {:extractor, in_umbrella: true},
      {:hackney, "~> 1.15"},
      {:initializer, in_umbrella: true},
      {:jason, "~> 1.1"},
      {:management, in_umbrella: true},
      {:metrics_reporter, in_umbrella: true},
      {:plugins, in_umbrella: true},
      {:poison, "~> 4.0"},
      {:properties, in_umbrella: true},
      {:protocol_source, in_umbrella: true},
      {:sweet_xml, "~> 0.6.6"},
      {:timex, "~> 3.6"},
      {:transformer, in_umbrella: true},
      {:checkov, "~> 1.0", only: [:dev, :test]},
      {:credo, "~> 1.3", only: [:dev]},
      {:mox, "~> 0.5", only: [:test]},
      {:placebo, "~> 2.0.0-rc.2", only: [:dev, :test]},
      {:testing, in_umbrella: true, only: [:test]}
    ]
  end

  defp elixirc_paths(:test), do: ["test/support", "lib"]
  defp elixirc_paths(_), do: ["lib"]
end

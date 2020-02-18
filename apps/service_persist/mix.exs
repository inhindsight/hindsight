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
      {:definition_dictionary, in_umbrella: true},
      {:definition_events, in_umbrella: true},
      {:ex_aws_s3, "~> 2.0"},
      {:extractor, in_umbrella: true},
      {:hackney, "~> 1.15"},
      {:initializer, in_umbrella: true},
      {:jason, "~> 1.1"},
      {:management, in_umbrella: true},
      {:off_broadway_kafka, "~> 0.5"},
      {:poison, "~> 4.0"},
      {:properties, in_umbrella: true},
      {:sweet_xml, "~> 0.6.6"},
      {:transformer, in_umbrella: true},
      {:writer_dlq, in_umbrella: true},
      {:writer_presto, in_umbrella: true},

      # Dev/Test Dependencies
      {:mox, "~> 0.5", only: [:test]},
      {:placebo, "~> 2.0.0-rc.2", only: [:dev, :test]},
      {:testing, in_umbrella: true, only: [:test]}
    ]
  end

  defp elixirc_paths(:test), do: ["test/support", "lib"]
  defp elixirc_paths(_), do: ["lib"]
end

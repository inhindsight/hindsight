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
      {:writer_presto, in_umbrella: true},
      {:writer_dlq, in_umbrella: true},
      {:definition_events, in_umbrella: true},
      {:simple_registry, in_umbrella: true},
      {:initializer, in_umbrella: true},
      {:annotated_retry, in_umbrella: true},
      {:properties, in_umbrella: true},
      {:jason, "~> 1.1"},
      {:off_broadway_kafka, "~> 0.5.0"},
      {:mox, "~> 0.5", only: [:test]},
      {:testing, in_umbrella: true}
    ]
  end

  defp elixirc_paths(:test), do: ["test/support", "lib"]
  defp elixirc_paths(_), do: ["lib"]
end

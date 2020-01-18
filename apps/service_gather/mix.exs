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
      {:brook, "~> 0.4.9"},
      {:definition_data, in_umbrella: true},
      {:definition_extract, in_umbrella: true},
      {:definition_events, in_umbrella: true},
      {:extract_steps, in_umbrella: true},
      {:extract_http, in_umbrella: true},
      {:extract_decode_gtfs, in_umbrella: true},
      {:extract_decode_csv, in_umbrella: true},
      {:extract_decode_json, in_umbrella: true},
      {:writer, in_umbrella: true},
      {:writer_kafka, in_umbrella: true},
      {:writer_dlq, in_umbrella: true},
      {:properties, in_umbrella: true},
      {:annotated_retry, in_umbrella: true},
      {:elixir_uuid, "~> 1.2"},
      {:retry, "~> 0.13.0"},
      {:initializer, in_umbrella: true},
      {:bypass, "~> 1.0", only: [:test]},
      {:testing, in_umbrella: true, only: [:test]},
      {:mox, "~> 0.5.1", only: [:test]}
    ]
  end

  defp elixirc_paths(:test), do: ["test/support", "lib"]
  defp elixirc_paths(_), do: ["lib"]
end

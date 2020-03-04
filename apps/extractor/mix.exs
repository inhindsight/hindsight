defmodule Extract.Steps.MixProject do
  use Mix.Project

  def project do
    [
      app: :extractor,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      consolidate_protocols: Mix.env() != :test
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:elsa, "~> 0.12", override: true},
      {:extract_step, in_umbrella: true},
      {:extract_decode_csv, in_umbrella: true},
      {:extract_decode_gtfs, in_umbrella: true},
      {:extract_decode_json, in_umbrella: true},
      {:extract_http, in_umbrella: true},
      {:extract_kafka, in_umbrella: true},
      {:ok, in_umbrella: true},
      {:definition, in_umbrella: true},
      {:dialyxir, "~> 1.0.0-rc.7", only: [:dev], runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end

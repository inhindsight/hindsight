defmodule ExtractGtfs.MixProject do
  use Mix.Project

  def project do
    [
      app: :extract_gtfs,
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
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:definition_extract, in_umbrella: true},
      {:extract_steps, in_umbrella: true},
      {:protobuf, "~> 0.7.0"}
    ]
  end
end

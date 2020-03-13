defmodule ExtractDecodeCsv.MixProject do
  use Mix.Project

  def project do
    [
      app: :extract_decode_csv,
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
      {:definition, in_umbrella: true},
      {:extract_step, in_umbrella: true},
      {:nimble_csv, "~> 0.6.0"},
      {:dialyxir, "~> 1.0.0-rc.7", only: [:dev], runtime: false},
      {:checkov, "~> 1.0", only: [:dev, :test]},
      {:brook_serializer, "~> 2.2", only: [:test]}
    ]
  end
end

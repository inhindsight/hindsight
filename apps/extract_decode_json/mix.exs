defmodule ExtractDecodeJson.MixProject do
  use Mix.Project

  def project do
    [
      app: :extract_decode_json,
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
      {:extract_steps, in_umbrella: true},
      {:definition, in_umbrella: true},
      {:jason, "~> 1.1"},
      {:temp, "~> 0.4.7"},
      {:dialyxir, "~> 1.0.0-rc.7", only: [:dev], runtime: false},
      {:checkov, "~> 1.0", only: [:dev, :test]},
      {:brook_serializer, "~> 2.2", only: [:test]}
    ]
  end
end

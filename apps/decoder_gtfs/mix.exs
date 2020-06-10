defmodule DecoderGtfs.MixProject do
  use Mix.Project

  def project do
    [
      app: :decoder_gtfs,
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
      {:protocol_decoder, in_umbrella: true},
      {:protobuf, "~> 0.7.0"},
      {:json_serde, "~> 1.0"},
      {:temp, "~> 0.4.7", only: [:test]},
      {:checkov, "~> 1.0", only: [:dev, :test]},
      {:credo, "~> 1.3", only: [:dev]}
    ]
  end
end

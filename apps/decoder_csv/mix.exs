defmodule DecoderCsv.MixProject do
  use Mix.Project

  def project do
    [
      app: :decoder_csv,
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
      {:nimble_csv, "~> 0.6.0"},
      {:brook_serializer, "~> 2.2", only: [:test]},
      {:checkov, "~> 1.0", only: [:dev, :test]},
      {:credo, "~> 1.3", only: [:dev]},
      {:dialyxir, "~> 1.0.0-rc.7", only: [:dev], runtime: false}
    ]
  end
end

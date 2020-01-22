defmodule Definition.MixProject do
  use Mix.Project

  def project do
    [
      app: :definition,
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
      {:ok, in_umbrella: true},
      {:norm, "~> 0.10.2"},
      {:jason, "~> 1.1"},
      {:dialyxir, "~> 1.0.0-rc.7", only: [:dev], runtime: false},
      {:stream_data, "~> 0.4.0", only: [:dev, :test]}
    ]
  end
end

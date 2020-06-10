defmodule Transform.WKT.MixProject do
  use Mix.Project

  def project do
    [
      app: :transform_wkt,
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
      {:definition_dictionary, in_umbrella: true},
      {:geo, "~> 3.3"},
      {:protocol_transform_step, in_umbrella: true},
      {:json_serde, "~> 1.0"},
      {:credo, "~> 1.3", only: [:dev]}
    ]
  end
end

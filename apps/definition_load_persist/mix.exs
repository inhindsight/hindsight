defmodule DefinitionLoadPersist.MixProject do
  use Mix.Project

  def project do
    [
      app: :definition_load_persist,
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
      {:protocol_source, in_umbrella: true},
      {:checkov, "~> 1.0", only: [:dev, :test]},
      {:testing, in_umbrella: true, only: [:test]}
    ]
  end
end

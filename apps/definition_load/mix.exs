defmodule DefinitionLoad.MixProject do
  use Mix.Project

  def project do
    [
      app: :definition_load,
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
      {:protocol_source, in_umbrella: true},
      {:protocol_destination, in_umbrella: true},
      {:credo, "~> 1.3", only: [:dev]},
      {:uuid, "~> 1.1"},

      # Dev/Test Dependencies
      {:placebo, "~> 2.0.0-rc.2", only: [:dev, :test]},
      {:testing, in_umbrella: true, only: [:test]}
    ]
  end
end

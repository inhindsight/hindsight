defmodule DefinitionDictionary.MixProject do
  use Mix.Project

  def project do
    [
      app: :definition_dictionary,
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
      {:definition, in_umbrella: true},
      {:jason, "~> 1.1"},
      {:json_serde, "~> 1.0"},
      {:timex, "~> 3.6"},
      {:checkov, "~> 1.0", only: [:dev, :test]},
      {:credo, "~> 1.3", only: [:dev]}
    ]
  end
end

defmodule DefinitionPresto.MixProject do
  use Mix.Project

  def project do
    [
      app: :definition_presto,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:annotated_retry, in_umbrella: true},
      {:avro, in_umbrella: true},
      {:definition_load, in_umbrella: true},
      {:definition_dictionary, in_umbrella: true},
      {:ex_aws_s3, "~> 2.0"},
      {:prestige, "~> 1.0"},
      {:properties, in_umbrella: true},
      {:sweet_xml, "~> 0.6.6"},
      {:tesla, "~> 1.3"},
      {:hackney, "~> 1.15.2"},
      {:divo, "~> 1.1", only: [:dev, :test]},
      {:checkov, "~> 1.0", only: [:dev, :test]},
      {:mox, "~> 0.5.1", only: [:test]},
      {:placebo, "~> 2.0.0-rc.2", only: [:dev, :test]},
      {:testing, in_umbrella: true}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end

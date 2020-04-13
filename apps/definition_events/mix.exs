defmodule DefinitionEvents.MixProject do
  use Mix.Project

  def project do
    [
      app: :definition_events,
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
      {:brook, "~> 0.5"},
      {:elsa, "~> 0.12", override: true},
      {:definition_accept, in_umbrella: true},
      {:definition_channel, in_umbrella: true},
      {:definition_kafka, in_umbrella: true},
      {:definition_presto, in_umbrella: true},
      {:definition_delete, in_umbrella: true},
      {:definition_extract, in_umbrella: true},
      {:definition_load, in_umbrella: true},
      {:definition_profile_update, in_umbrella: true},
      {:definition_schedule, in_umbrella: true},
      {:extractor, in_umbrella: true},
      {:credo, "~> 1.3", only: [:dev]}
    ]
  end
end

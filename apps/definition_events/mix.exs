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
      {:elsa, git: "https://github.com/bbalser/elsa", override: true},
      {:definition_accept, in_umbrella: true},
      {:definition_extract, in_umbrella: true},
      {:definition_load_broadcast, in_umbrella: true},
      {:definition_load_persist, in_umbrella: true},
      {:definition_schedule, in_umbrella: true}
    ]
  end
end

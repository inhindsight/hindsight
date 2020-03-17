defmodule Profile.MixProject do
  use Mix.Project

  def project do
    [
      app: :service_profile,
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
      extra_applications: [:logger],
      mod: {Profile.Application, []}
    ]
  end

  defp deps do
    [
      {:brook, "~> 0.5"},
      {:extractor, in_umbrella: true},
      {:definition_dictionary, in_umbrella: true},
      {:definition_events, in_umbrella: true},
      {:elsa, "~> 0.12", override: true},
      {:flow, "~> 1.0"},
      {:gen_stage, "~> 1.0", override: true},
      {:properties, in_umbrella: true},

      # dev/testing deps
      {:testing, in_umbrella: true, only: [:test]}
    ]
  end

  defp elixirc_paths(:test), do: ["test/support", "lib"]
  defp elixirc_paths(_), do: ["lib"]
end

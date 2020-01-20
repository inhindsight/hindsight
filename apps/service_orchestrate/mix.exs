defmodule Orchestrate.MixProject do
  use Mix.Project

  def project do
    [
      app: :service_orchestrate,
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
      extra_applications: [:logger],
      mod: {Orchestrate.Application, []}
    ]
  end

  defp deps do
    [
      {:quantum, "~> 2.3"},
      {:timex, "~> 3.0"},
      {:brook, "~> 0.5"},
      {:uuid, "~> 1.1"},
      {:definition_events, in_umbrella: true},
      {:properties, in_umbrella: true},
      {:testing, in_umbrella: true, only: [:test]},
      {:placebo, "~> 2.0.0-rc.2", only: [:dev, :test]}
    ]
  end
end

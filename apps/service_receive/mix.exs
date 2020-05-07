defmodule Receive.MixProject do
  use Mix.Project

  def project do
    [
      app: :service_receive,
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
      mod: {Receive.Application, []}
    ]
  end

  defp deps do
    [
      {:accept_udp, in_umbrella: true},
      {:accept_websocket, in_umbrella: true},
      {:annotated_retry, in_umbrella: true},
      {:brook, "~> 0.5"},
      {:brook_storage_postgres, "~> 0.1.0"},
      {:definition_accept, in_umbrella: true},
      {:definition_dictionary, in_umbrella: true},
      {:definition_events, in_umbrella: true},
      {:elsa, "~> 0.12", override: true},
      {:extractor, in_umbrella: true},
      {:initializer, in_umbrella: true},
      {:management, in_umbrella: true},
      {:metrics_reporter, in_umbrella: true},
      {:plugins, in_umbrella: true},
      {:properties, in_umbrella: true},
      {:transformer, in_umbrella: true},
      {:credo, "~> 1.3", only: [:dev]},
      {:dialyxir, "~> 1.0.0-rc.7", only: [:dev], runtime: false},
      {:mox, "~> 0.5.1", only: [:test]},
      {:placebo, "~> 2.0.0-rc2", only: [:dev, :test]},
      {:testing, in_umbrella: true, only: [:test]}
    ]
  end

  defp elixirc_paths(:test), do: ["test/support", "lib"]
  defp elixirc_paths(_), do: ["lib"]
end

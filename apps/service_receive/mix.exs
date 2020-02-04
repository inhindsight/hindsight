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
      deps: deps()
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
      {:brook, "~> 0.5"},
      {:definition_accept, in_umbrella: true},
      {:definition_events, in_umbrella: true},
      {:initializer, in_umbrella: true},
      {:properties, in_umbrella: true},
      {:writer_kafka, in_umbrella: true},
      {:testing, in_umbrella: true, only: [:test]},
      {:mox, "~> 0.5.1", only: [:test]},
      {:dialyxir, "~> 1.0.0-rc.7", only: [:dev], runtime: false}
    ]
  end
end

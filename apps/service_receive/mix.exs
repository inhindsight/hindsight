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
      # Remove this override when gun releases a 2.0+ vs. to hex using cowlib 2.8
      {:cowlib, "~> 2.8.0", override: true},
      {:accept_udp, in_umbrella: true},
      {:annotated_retry, in_umbrella: true},
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

  defp elixirc_paths(:test), do: ["test/support", "lib"]
  defp elixirc_paths(_), do: ["lib"]
end

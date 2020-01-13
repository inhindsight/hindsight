defmodule Broadcast.MixProject do
  use Mix.Project

  def project do
    [
      app: :service_broadcast,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Broadcast.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.4.11"},
      {:phoenix_pubsub, "~> 1.1"},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.1"},
      {:plug_cowboy, "~> 2.0"},
      {:brook, "~> 0.4.9"},
      {:off_broadway_kafka, "~> 0.5.0"},
      {:definition, in_umbrella: true},
      {:definition_load_broadcast, in_umbrella: true},
      {:definition_events, in_umbrella: true},
      {:simple_registry, in_umbrella: true},
      {:initializer, in_umbrella: true},
      {:checkov, "~> 1.0", only: [:dev, :test]}
    ]
  end
end

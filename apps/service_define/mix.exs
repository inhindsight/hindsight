defmodule Define.MixProject do
  use Mix.Project

  def project do
    [
      app: :service_define,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {Define.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:metrics_reporter, in_umbrella: true},
      {:phoenix, "~> 1.4.15"},
      {:phoenix_pubsub, "~> 1.1"},
      {:plug_cowboy, "~> 2.0"},
      {:properties, in_umbrella: true},

      # Dev/Test dependencies
      {:phoenix_live_reload, "~> 1.2", only: [:dev]},
      {:testing, in_umbrella: true, only: [:test]}
    ]
  end
end

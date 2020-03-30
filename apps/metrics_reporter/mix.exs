defmodule MetricsReporter.MixProject do
  use Mix.Project

  def project do
    [
      app: :metrics_reporter,
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
      {:telemetry_poller, "~> 0.5.0"},
      {:telemetry_metrics_prometheus, "~> 0.4.0"},

      # Dev/Test Dependencies
      {:tesla, "~> 1.3", only: [:test]},
      {:testing, in_umbrella: true, only: [:test]}
    ]
  end
end

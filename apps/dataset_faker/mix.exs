defmodule DatasetFaker.MixProject do
  use Mix.Project

  def project do
    [
      app: :dataset_faker,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:faker, "~> 0.12"},
      {:dialyxir, "~> 1.0.0-rc.6", only: [:dev], runtime: false},
    ]
  end
end

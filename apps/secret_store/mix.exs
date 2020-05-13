defmodule SecretStore.MixProject do
  use Mix.Project

  def project do
    [
      app: :secret_store,
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

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_aws, "~> 2.1"},
      {:ex_aws_secretsmanager, "~> 2.0"},
      {:hackney, "~> 1.15"},
      {:jason, "~> 1.1"},
      {:ok, in_umbrella: true},
      {:poison, "~> 4.0"},
      {:credo, "~> 1.3", only: [:dev]},
      {:dialyxir, "~> 1.0.0-rc.7", only: [:dev], runtime: false},
      {:placebo, "~> 2.0.0-rc2", only: [:dev, :test]}
    ]
  end
end

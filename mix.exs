defmodule Hindsight.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      preferred_cli_env: ["test.unit": :test, "test.int": :test],
      dialyzer: [
        plt_add_apps: [:ex_unit, :eex],
        plt_file: {:no_warn, ".dialyzer/#{System.version()}.plt"}
      ]
    ]
  end

  defp deps do
    []
  end

  defp aliases() do
    [
      "test.unit": "test --exclude integration --exclude performance --exclude e2e",
      "test.int": "test --only integration",
      "test.e2e": "cmd --app platform_runner mix test.integration --only e2e --color"
    ]
  end
end

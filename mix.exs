defmodule Hindsight.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases(),
      aliases: aliases(),
      preferred_cli_env: ["test.unit": :test, "test.int": :test],
      dialyzer: [
        plt_add_apps: [:ex_unit, :eex],
        plt_file: {:no_warn, ".dialyzer/#{System.version()}.plt"}
      ]
    ]
  end

  defp releases do
    [
      orchestrate: [
        version: {:from_app, :service_orchestrate},
        include_executables_for: [:unix],
        applications: [service_orchestrate: :permanent]
      ],
      receive: [
        version: {:from_app, :service_receive},
        include_executables_for: [:unix],
        applications: [service_receive: :permanent]
      ],
      gather: [
        version: {:from_app, :service_gather},
        include_executables_for: [:unix],
        applications: [service_gather: :permanent]
      ],
      broadcast: [
        version: {:from_app, :service_broadcast},
        include_executables_for: [:unix],
        applications: [service_broadcast: :permanent]
      ],
      persist: [
        version: {:from_app, :service_persist},
        include_executables_for: [:unix],
        applications: [service_persist: :permanent]
      ],
      acquire: [
        version: {:from_app, :service_acquire},
        include_executables_for: [:unix],
        applications: [service_acquire: :permanent]
      ],
      define: [
        version: {:from_app, :service_define},
        include_executables_for: [:unix],
        applications: [service_define: :permanent],
        # This is necessary for Define.TypespecAnalysis to have typespec data
        strip_beams: false
      ]
    ]
  end

  defp deps do
    [
      {:cowlib, "~> 2.8.0", override: true}
    ]
  end

  defp aliases() do
    [
      "test.unit": "test --exclude integration --exclude performance --exclude e2e --color",
      "test.int": "test --only integration --color",
      "test.e2e": "cmd --app platform_runner mix test.integration --only e2e --color",
      "test.perf": "cmd --app platform_runner mix test.integration --only performance --color"
    ]
  end
end

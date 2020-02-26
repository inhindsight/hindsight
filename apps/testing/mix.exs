defmodule Testing.MixProject do
  use Mix.Project

  def project do
    [
      app: :testing,
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
      # Remove this override when gun releases a 2.0+ vs. to hex using cowlib 2.8
      {:cowlib, "~> 2.8.0", override: true},
      {:glock, github: "jeffgrunewald/glock", tag: "0.1.0"}
    ]
  end
end

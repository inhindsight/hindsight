defmodule MetricsReporter do
  @moduledoc """
  Defines a behaviour and default implementation of a
  process for handling and reporting application metrics
  gathered from telemetry events to a webserver for scraping
  by a Prometheus instance.
  """

  @callback metrics() :: [
              Telemetry.Metrics.Counter.t()
              | Telemetry.Metrics.Distribution.t()
              | Telemetry.Metrics.LastValue.t()
              | Telemetry.Metrics.Sum.t()
              | Telemetry.Metrics.Summary.t()
            ]

  defmacro __using__(opts) do
    name = Keyword.fetch!(opts, :name)
    port = Keyword.get(opts, :port, 9568)

    quote location: :keep do
      use Supervisor
      import Telemetry.Metrics
      @behaviour MetricsReporter

      def start_link(_args) do
        Supervisor.start_link(__MODULE__, [], name: unquote(name))
      end

      @impl Supervisor
      def init(_args) do
        children = [
          {TelemetryMetricsPrometheus, name: :"#{unquote(name)}_prometheus", port: unquote(port), metrics: metrics()}
        ]

        Supervisor.init(children, strategy: :one_for_one)
      end

      @impl true
      def metrics() do
        [
          last_value("vm.memory.total", unit: :byte),
          last_value("vm.total_run_queue_lengths.total"),
          last_value("vm.total_run_queue_lengths.cpu"),
          last_value("vm.total_run_queue_lengths.io")
        ]
      end

      defoverridable metrics: 0
    end
  end
end

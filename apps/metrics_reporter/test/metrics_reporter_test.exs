defmodule MetricsReporterTest do
  use ExUnit.Case
  import AssertAsync

  setup do
    start_supervised({MetricsTest, []})

    :ok
  end

  test "exports metrics to /metrics" do
    assert_async max_tries: 10, sleep: 1_000 do
      {:ok, %Tesla.Env{body: resp_body}} = Tesla.get("http://localhost:9568/metrics")

      assert String.contains?(resp_body, "vm_total_run_queue_lengths_io")
      assert String.contains?(resp_body, "vm_total_run_queue_lengths_cpu")
      assert String.contains?(resp_body, "vm_total_run_queue_lengths_total")
      assert String.contains?(resp_body, "vm_memory_total")
    end
  end
end

defmodule MetricsTest do
  use MetricsReporter, name: :metrics_test
end

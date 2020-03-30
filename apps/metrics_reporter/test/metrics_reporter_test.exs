defmodule MetricsReporterTest do
  use ExUnit.Case
  doctest MetricsReporter

  test "greets the world" do
    assert MetricsReporter.hello() == :world
  end
end

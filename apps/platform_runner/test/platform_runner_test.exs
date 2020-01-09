defmodule PlatformRunnerTest do
  use ExUnit.Case
  doctest PlatformRunner

  test "greets the world" do
    assert PlatformRunner.hello() == :world
  end
end

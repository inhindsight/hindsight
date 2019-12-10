defmodule DatasetFakerTest do
  use ExUnit.Case
  doctest DatasetFaker

  test "greets the world" do
    assert DatasetFaker.hello() == :world
  end
end

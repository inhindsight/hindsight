defmodule DataTest do
  use ExUnit.Case
  doctest Data

  test "greets the world" do
    assert Data.hello() == :world
  end
end

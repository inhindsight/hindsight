defmodule ProfileTest do
  use ExUnit.Case
  doctest Profile

  test "greets the world" do
    assert Profile.hello() == :world
  end
end

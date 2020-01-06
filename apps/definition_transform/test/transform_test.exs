defmodule TransformTest do
  use ExUnit.Case
  doctest Transform

  test "greets the world" do
    assert Transform.hello() == :world
  end
end

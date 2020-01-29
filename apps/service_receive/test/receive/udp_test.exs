defmodule Receive.UDPTest do
  use ExUnit.Case
  doctest Receive.UDP

  test "greets the world" do
    assert Receive.UDP.hello() == :world
  end
end

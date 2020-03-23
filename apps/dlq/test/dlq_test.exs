defmodule DlqTest do
  use ExUnit.Case
  doctest Dlq

  test "greets the world" do
    assert Dlq.hello() == :world
  end
end

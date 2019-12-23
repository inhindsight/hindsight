defmodule ScheduleTest do
  use ExUnit.Case
  doctest Schedule

  test "greets the world" do
    assert Schedule.hello() == :world
  end
end

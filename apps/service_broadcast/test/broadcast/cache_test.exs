defmodule Broadcast.CacheTest do
  use ExUnit.Case
  require Temp.Env

  alias Broadcast.Cache

  Temp.Env.modify([
    %{app: :service_broadcast, key: Broadcast.Cache, set: [cache_size: 10]}
  ])

  setup do
    {:ok, pid} = Broadcast.Cache.start_link([])

    [pid: pid]
  end

  test "can add value to cache and retrieve entire cache in order", %{pid: pid} do
    assert :ok == Cache.add(pid, ["one"])
    assert :ok == Cache.add(pid, ["two", "three"])
    assert :ok == Cache.add(pid, ["four"])

    assert ["one", "two", "three", "four"] == Cache.get(pid)
  end

  test "will trim list when goes over the configured cache_size", %{pid: pid} do
    Enum.each(1..100, fn i -> Cache.add(pid, [i]) end)

    result = Cache.get(pid)

    assert [91, 92, 93, 94, 95, 96, 97, 98, 99, 100] == result
  end
end

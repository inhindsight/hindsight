defmodule SimpleRegistryTest do
  use ExUnit.Case
  import AssertAsync

  defmodule TestServer do
    use GenServer

    def start_link(args) do
      GenServer.start_link(__MODULE__, args)
    end

    def init(args) do
      pid = Keyword.fetch!(args, :pid)
      {:ok, %{pid: pid}}
    end

    def handle_info(message, state) do
      send(state.pid, message)
      {:noreply, state}
    end
  end

  @name :test_registry

  setup do
    Process.flag(:trap_exit, true)
    {:ok, registry} = SimpleRegistry.start_link(name: @name)

    on_exit(fn -> assert_down(registry) end)

    :ok
  end

  test "process can be registerd with via tuple" do
    {:ok, pid} =
      Agent.start_link(fn -> :agent_1 end, name: {:via, SimpleRegistry, {@name, :agent1}})

    assert :agent_1 == Agent.get({:via, SimpleRegistry, {@name, :agent1}}, fn s -> s end)

    assert_down(pid)
  end

  test "name can only be registered one time" do
    {:ok, pid1} =
      Agent.start_link(fn -> :agent1 end, name: {:via, SimpleRegistry, {@name, :agent1}})

    assert {:error, {:already_started, ^pid1}} =
             Agent.start_link(fn -> :agent2 end, name: {:via, SimpleRegistry, {@name, :agent1}})

    assert_down(pid1)
  end

  test "process is removed from registry after it dies" do
    {:ok, pid} =
      Agent.start_link(fn -> :agent1 end, name: {:via, SimpleRegistry, {@name, :agent1}})

    assert ^pid = SimpleRegistry.whereis_name({@name, :agent1})

    assert_down(pid)

    assert_async do
      assert :undefined = SimpleRegistry.whereis_name({@name, :agent1})
    end
  end

  test "name can be unregisterd" do
    {:ok, pid} =
      Agent.start_link(fn -> :agent1 end, name: {:via, SimpleRegistry, {@name, :agent1}})

    assert ^pid = SimpleRegistry.whereis_name({@name, :agent1})
    assert :ok = SimpleRegistry.unregister_name({@name, :agent1})

    assert_async do
      assert :undefined == SimpleRegistry.whereis_name({@name, :agent1})
    end

    assert_down(pid)
  end

  test "send will send a message to registered process" do
    {:ok, pid} = TestServer.start_link(pid: self())
    assert :yes = SimpleRegistry.register_name({@name, :server1}, pid)

    SimpleRegistry.send({@name, :server1}, :hello)

    assert_receive :hello

    assert_down(pid)
  end

  test "registered processes will show all processes" do
    {:ok, pid1} =
      Agent.start_link(fn -> :agent1 end, name: {:via, SimpleRegistry, {@name, :agent1}})

    {:ok, pid2} = TestServer.start_link(pid: self())
    SimpleRegistry.register_name({@name, :server1}, pid2)

    processes = SimpleRegistry.registered_processes(@name)
    assert pid1 == Keyword.get(processes, :agent1)
    assert pid2 == Keyword.get(processes, :server1)
  end

  defp assert_down(pid) do
    ref = Process.monitor(pid)
    Process.exit(pid, :kill)
    assert_receive {:DOWN, ^ref, _, _, _}
  end
end

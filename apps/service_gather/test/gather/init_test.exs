defmodule Gather.InitTest do
  use Gather.Case
  import Mox
  require Temp.Env

  alias Gather.Extraction

  @moduletag capture_log: true

  @instance Gather.Application.instance()

  Temp.Env.modify([
    %{app: :service_gather, key: Gather.Extraction, update: fn config ->
       Keyword.put(config, :writer, Gather.WriterMock)
     end}
  ])

  setup :set_mox_global
  setup :verify_on_exit!

  setup do
    Process.flag(:trap_exit, true)

    :ok
  end

  test "should start any existing extractions" do
    test = self()

    steps = [
      %{step: "Fake.Step", values: [%{"one" => "1"}]}
    ]

    extracts = [
      Extract.new!(
        id: "ex1",
        dataset_id: "init_ds1",
        name: "n1",
        steps: steps,
        destination: "topic1"
      ),
      Extract.new!(
        id: "ex2",
        dataset_id: "init_ds2",
        name: "n2",
        steps: steps,
        destination: "topic2"
      )
    ]

    Brook.Test.with_event(@instance, fn ->
      Enum.each(extracts, &Extraction.Store.persist/1)
    end)

    Gather.WriterMock
    |> stub(:start_link, fn args ->
      send(test, {:start_link, args})
      Agent.start_link(fn -> :dummy end)
    end)

    {:ok, pid} = Gather.Init.start_link(name: :init_test)

    Enum.each(extracts, fn extract ->
      assert_receive {:start_link, [extract: ^extract]}, 5_000
    end)

    assert_down(pid)
    Gather.Extraction.Supervisor.kill_all_children()
  end

  defp assert_down(pid) do
    ref = Process.monitor(pid)
    Process.exit(pid, :kill)
    assert_receive {:DOWN, ^ref, _, _, _}
  end
end

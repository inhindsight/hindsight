defmodule Gather.InitTest do
  use Gather.Case
  import Mox

  alias Gather.Extraction

  @moduletag capture_log: true

  @instance Gather.Application.instance()

  setup :set_mox_global
  setup :verify_on_exit!

  setup do
    on_exit(fn ->
      __cleanup_supervisor__()
    end)

    :ok
  end

  test "should start any existing extractions" do
    test = self()

    steps = [
      %{step: "Fake.Step", values: [%{"one" => "1"}]}
    ]

    extracts = [
      Extract.new!(id: "ex1", dataset_id: "ds1", name: "n1", steps: steps),
      Extract.new!(id: "ex2", dataset_id: "ds2", name: "n2", steps: steps)
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
    on_exit(fn -> assert_down(pid) end)

    Enum.each(extracts, fn extract ->
      assert_receive {:start_link, [extract: ^extract]}, 5_000
    end)
  end

  defp assert_down(pid) do
    ref = Process.monitor(pid)
    Process.exit(pid, :kill)
    assert_receive {:DOWN, ^ref, _, _, _}
  end
end

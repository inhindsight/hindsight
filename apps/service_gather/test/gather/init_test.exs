defmodule Gather.InitTest do
  use Gather.Case

  alias Gather.Extraction

  @moduletag capture_log: true

  @instance Gather.Application.instance()

  setup do
    Process.flag(:trap_exit, true)

    :ok
  end

  test "should start any existing extractions" do
    extracts = [
      Extract.new!(
        id: "ex1",
        dataset_id: "init_ds1",
        subset_id: "n1",
        source: Source.Fake.new!(),
        decoder: Decoder.JsonLines.new!([]),
        destination: Destination.Fake.new!()
      ),
      Extract.new!(
        id: "ex2",
        dataset_id: "init_ds2",
        subset_id: "n2",
        source: Source.Fake.new!(),
        decoder: Decoder.JsonLines.new!([]),
        destination: Destination.Fake.new!()
      )
    ]

    Brook.Test.with_event(@instance, fn ->
      Enum.each(extracts, &Extraction.Store.persist/1)
    end)

    {:ok, _pid} = start_supervised({Gather.Init, name: :init_test})

    assert_receive {:destination_start_link, id1}, 5_000
    assert_receive {:destination_start_link, id2}, 5_000

    refute id1 == id2

    Gather.Extraction.Supervisor.kill_all_children()
  end
end

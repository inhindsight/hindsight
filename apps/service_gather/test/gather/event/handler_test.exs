defmodule Gather.Event.HandlerTest do
  use ExUnit.Case
  use Placebo
  import AssertAsync

  import Events, only: [dataset_delete: 0]

  @instance Gather.Application.instance()

  describe "dataset_delete" do
    setup do
      allow Gather.Extraction.Supervisor.terminate_child(any()), return: :ok

      delete =
        Delete.new!(
          id: "delete-1",
          dataset_id: "ds1",
          subset_id: "sb1"
        )

      extract =
        Extract.new!(
          id: "extract-1",
          dataset_id: "ds1",
          subset_id: "sb1",
          source: Source.Fake.new!(),
          decoder: Decoder.Noop.new(),
          destination: Destination.Fake.new!(),
          dictionary: []
        )

      Brook.Test.with_event(@instance, fn ->
        Gather.Extraction.Store.persist(extract)
      end)

      Brook.Test.send(@instance, dataset_delete(), "testing", delete)

      [delete: delete, extract: extract]
    end

    test "stops any ongoing extractions", %{extract: extract} do
      assert_called Gather.Extraction.Supervisor.terminate_child(extract)
    end

    test "deletes extraction from view state", %{extract: extract} do
      assert_async do
        assert nil == Gather.Extraction.Store.get!(extract.dataset_id, extract.subset_id)
      end
    end

    test "deletes the source", %{extract: %{source: source}} do
      assert_receive {:source_delete, ^source}
    end

    test "deletes the destination", %{extract: %{destination: destination}} do
      assert_receive {:destination_delete, ^destination}
    end
  end
end

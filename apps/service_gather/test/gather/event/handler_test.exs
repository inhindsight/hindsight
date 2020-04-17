defmodule Gather.Event.HandlerTest do
  use Gather.Case
  use Placebo
  import AssertAsync
  alias Gather.ViewState

  import Definition, only: [identifier: 1]

  import Events,
    only: [
      extract_start: 0,
      extract_end: 0,
      dataset_delete: 0
    ]

  @instance Gather.Application.instance()

  setup do
    Process.flag(:trap_exit, true)

    extract =
      Extract.new!(
        id: "extract-1",
        dataset_id: "ds1",
        subset_id: "sb1",
        source: Source.Fake.new!(),
        destination: Destination.Fake.new!(),
        decoder: Decoder.Noop.new(),
        dictionary: Dictionary.from_list([])
      )

    allow Gather.Extraction.Supervisor.start_child(any()), return: :ok

    [extract: extract, key: identifier(extract)]
  end

  describe "handling #{extract_start()} events" do
    test "extraction is started", %{extract: extract} do
      expect Gather.Extraction.Supervisor.start_child(extract), return: :ok
      Brook.Test.send(@instance, extract_start(), "testing", extract)
    end

    test "extraction is stored in view state", %{extract: extract, key: key} do
      Brook.Test.send(@instance, extract_start(), "testing", extract)

      assert_async do
        assert {:ok, ^extract} = Gather.ViewState.Extractions.get(key)
      end
    end

    test "source and destination are stored in view state", %{extract: extract, key: key} do
      source = extract.source
      destination = extract.destination

      Brook.Test.send(@instance, extract_start(), "testing", extract)

      assert_async do
        assert {:ok, ^source} = Gather.ViewState.Sources.get(key)
        assert {:ok, ^destination} = Gather.ViewState.Destinations.get(key)
      end
    end
  end

  describe "handling #{extract_end()} events" do
    test "removes only extraction from view state", %{extract: extract, key: key} do
      source = extract.source
      destination = extract.destination

      Brook.Test.send(@instance, extract_start(), "testing", extract)

      assert_async do
        assert {:ok, ^extract} = ViewState.Extractions.get(key)
        assert {:ok, ^source} = ViewState.Sources.get(key)
        assert {:ok, ^destination} = ViewState.Destinations.get(key)
      end

      Brook.Test.send(@instance, extract_end(), "testing", extract)

      assert_async do
        assert {:ok, nil} = ViewState.Extractions.get(key)
        assert {:ok, ^source} = ViewState.Sources.get(key)
        assert {:ok, ^destination} = ViewState.Destinations.get(key)
      end
    end
  end

  describe "handling #{dataset_delete()} events" do
    setup do
      allow Gather.Extraction.Supervisor.terminate_child(any()), return: :ok
      delete = Delete.new!(id: "delete-1", dataset_id: "ds1", subset_id: "sb1")
      [delete: delete]
    end

    test "stops extraction if extraction in view state", %{extract: extract, delete: delete} do
      Brook.Test.send(@instance, extract_start(), "testing", extract)
      Brook.Test.send(@instance, dataset_delete(), "testing", delete)
      assert_called Gather.Extraction.Supervisor.terminate_child(extract)
    end

    test "deletes source and destination if extraction in view state", %{
      extract: extract,
      delete: delete
    } do
      source = extract.source
      destination = extract.destination

      Brook.Test.send(@instance, extract_start(), "testing", extract)
      Brook.Test.send(@instance, dataset_delete(), "testing", delete)

      assert_receive {:source_delete, ^source}, 1_000
      assert_receive {:destination_delete, ^destination}, 1_000
    end

    test "removes extraction, source, destination from view state if extraction found", %{
      extract: extract,
      delete: delete,
      key: key
    } do
      source = extract.source
      destination = extract.destination

      Brook.Test.send(@instance, extract_start(), "testing", extract)

      assert_async do
        assert {:ok, ^extract} = ViewState.Extractions.get(key)
        assert {:ok, ^source} = ViewState.Sources.get(key)
        assert {:ok, ^destination} = ViewState.Destinations.get(key)
      end

      Brook.Test.send(@instance, dataset_delete(), "testing", delete)

      assert_async do
        assert {:ok, nil} = ViewState.Extractions.get(key)
        assert {:ok, nil} = ViewState.Sources.get(key)
        assert {:ok, nil} = ViewState.Destinations.get(key)
      end
    end

    test "deletes source and destination if extraction not in view state", %{
      extract: extract,
      delete: delete,
      key: key
    } do
      source = extract.source
      destination = extract.destination

      Brook.Test.send(@instance, extract_start(), "testing", extract)

      assert_async do
        assert {:ok, ^extract} = ViewState.Extractions.get(key)
      end

      Brook.Test.send(@instance, extract_end(), "testing", extract)

      assert_async do
        assert {:ok, nil} = ViewState.Extractions.get(key)
      end

      Brook.Test.send(@instance, dataset_delete(), "testing", delete)

      assert_receive {:source_delete, ^source}, 1_000
      assert_receive {:destination_delete, ^destination}, 1_000
    end

    test "removes source and destination from view state if extraction not found", %{
      extract: extract,
      delete: delete,
      key: key
    } do
      source = extract.source
      destination = extract.destination

      Brook.Test.send(@instance, extract_start(), "testing", extract)

      assert_async do
        assert {:ok, ^extract} = ViewState.Extractions.get(key)
        assert {:ok, ^source} = ViewState.Sources.get(key)
        assert {:ok, ^destination} = ViewState.Destinations.get(key)
      end

      Brook.Test.send(@instance, extract_end(), "testing", extract)

      assert_async do
        assert {:ok, nil} = ViewState.Extractions.get(key)
      end

      Brook.Test.send(@instance, dataset_delete(), "testing", delete)

      assert_async do
        assert {:ok, nil} = ViewState.Sources.get(key)
        assert {:ok, nil} = ViewState.Destinations.get(key)
      end
    end
  end
end

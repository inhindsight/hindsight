defmodule Persist.Event.HandlerTest do
  use ExUnit.Case
  use Placebo
  import Mox
  require Temp.Env

  import Definition, only: [identifier: 1]

  import Events,
    only: [
      load_start: 0,
      transform_define: 0,
      load_end: 0,
      compact_start: 0,
      compact_end: 0,
      dataset_delete: 0
    ]

  alias Persist.ViewState

  @instance Persist.Application.instance()

  Temp.Env.modify([
    %{
      app: :definition_presto,
      key: Presto.Table.Compactor,
      set: [impl: Persist.CompactorMock]
    }
  ])

  setup :set_mox_global

  setup do
    allow(UUID.uuid4(), return: "fake_uuid")
    on_exit(fn ->
      [
        ViewState.Loads,
        ViewState.Transformations,
        ViewState.Compactions,
        ViewState.Sources,
        ViewState.Destinations
      ]
      |> Enum.each(&Brook.Test.clear_view_state(@instance, &1.collection()))
    end)

    load =
      Load.new!(
        id: "fake_uuid",
        dataset_id: "ds1",
        subset_id: "sb1",
        source: Source.Fake.new!(),
        destination:
          Presto.Table.new!(
            url: "http://localhost:8080",
            name: "table24"
          )
      )

    transform =
      Transform.new!(
        id: "transform-1",
        dataset_id: load.dataset_id,
        subset_id: load.subset_id,
        dictionary: [
          Dictionary.Type.String.new!(name: "name"),
          Dictionary.Type.Integer.new!(name: "age")
        ],
        steps: [
          Transform.MoveField.new!(from: "name", to: "fullname")
        ]
      )

    delete =
      Delete.new!(
        id: "delete-1",
        dataset_id: load.dataset_id,
        subset_id: load.subset_id
      )

    key = identifier(load)

    [load: load, transform: transform, key: key, delete: delete]
  end

  describe "handling #{load_start()} event" do
    setup context do
      allow Persist.Load.Supervisor.start_child(any()), return: :ok

      Brook.Test.with_event(@instance, fn ->
        ViewState.Transformations.persist(context.key, context.transform)
      end)

      Brook.Test.send(@instance, load_start(), "testing", context.load)
    end

    test "starts loader process", %{load: load} do
      assert_called Persist.Load.Supervisor.start_child(load)
    end

    test "stores load metadata", %{load: load, key: key} do
      assert {:ok, ^load} = ViewState.Loads.get(key)
    end

    test "stores source and destination metadata", %{load: load, key: key} do
      source = load.source
      destination = load.destination

      assert {:ok, ^source} = ViewState.Sources.get(key)
      assert {:ok, ^destination} = ViewState.Destinations.get(key)
    end
  end

  describe "handling #{transform_define()} event" do
    test "stores transformation metadata", %{transform: transform, key: key} do
      Brook.Test.send(@instance, transform_define(), "testing", transform)
      assert {:ok, ^transform} = ViewState.Transformations.get(key)
    end
  end

  describe "handling #{load_end()} event" do
    setup context do
      allow Persist.Load.Supervisor.terminate_child(context.load), return: :ok

      Brook.Test.with_event(@instance, fn ->
        ViewState.Loads.persist(context.key, context.load)
        ViewState.Sources.persist(context.key, context.load.source)
        ViewState.Destinations.persist(context.key, context.load.destination)
        ViewState.Transformations.persist(context.key, context.transform)
      end)

      Brook.Test.send(@instance, load_end(), "testing", context.load)
    end

    test "terminates loader process", %{load: load} do
      assert_called Persist.Load.Supervisor.terminate_child(load)
    end

    test "triggers compaction", %{load: load} do
      assert_receive {:brook_event, %{type: compact_start(), data: ^load}}
    end

    test "removes load metadata from state", %{key: key} do
      assert {:ok, nil} = ViewState.Loads.get(key)
    end
  end

  describe "handling #{compact_start()} event" do
    setup context do
      test = self()

      stub(Persist.CompactorMock, :compact, fn table ->
        send(test, {:compact, table})
        :ok
      end)

      allow Persist.Load.Supervisor.terminate_child(any()), return: :ok
      Brook.Test.send(@instance, compact_start(), "testing", context.load)
    end

    test "terminates loader process", %{load: load} do
      assert_called Persist.Load.Supervisor.terminate_child(load)
    end

    test "starts compactor process", %{load: %{destination: destination} = load} do
      assert_receive {:compact, ^destination}, 2_000
      assert_receive {:brook_event, %Brook.Event{type: compact_end(), data: ^load}}
    end

    test "stores compaction metadata", %{load: load, key: key} do
      assert {:ok, ^load} = ViewState.Compactions.get(key)
    end
  end

  describe "handling #{compact_end()} event with load metadata" do
    setup context do
      allow Persist.Load.Supervisor.start_child(any()), return: :ok

      Brook.Test.with_event(@instance, fn ->
        ViewState.Loads.persist(context.key, context.load)
        ViewState.Compactions.persist(context.key, context.load)
      end)

      Brook.Test.send(@instance, compact_end(), "testing", context.load)
    end

    test "restarts loader process", %{load: load} do
      assert_called Persist.Load.Supervisor.start_child(load)
    end

    test "removes compaction metadata", %{key: key} do
      assert {:ok, nil} = ViewState.Compactions.get(key)
    end
  end

  describe "handling #{compact_end()} event without load metadata" do
    setup context do
      allow Persist.Load.Supervisor.start_child(any()), return: :ok

      Brook.Test.with_event(@instance, fn ->
        ViewState.Compactions.persist(context.key, context.load)
      end)

      Brook.Test.send(@instance, compact_end(), "testing", context.load)
    end

    test "ignores loader process", %{load: load} do
      refute_called Persist.Load.Supervisor.start_child(load)
    end

    test "removes compaction metadata", %{key: key} do
      assert {:ok, nil} = ViewState.Compactions.get(key)
    end
  end

  describe "handling #{dataset_delete()} event for existing load" do
    setup context do
      allow Persist.Compact.Supervisor.terminate_child(any()), return: :ok
      allow Persist.Load.Supervisor.terminate_child(any()), return: :ok
      allow Presto.Table.Destination.delete(any()), return: :ok

      Brook.Test.with_event(@instance, fn ->
        ViewState.Loads.persist(context.key, context.load)
        ViewState.Sources.persist(context.key, context.load.source)
        ViewState.Destinations.persist(context.key, context.load.destination)
        ViewState.Transformations.persist(context.key, context.transform)
        ViewState.Compactions.persist(context.key, context.load)
      end)

      Brook.Test.send(@instance, dataset_delete(), "testing", context.delete)
    end

    test "deletes compactor", %{load: load, key: key} do
      assert_called Persist.Compact.Supervisor.terminate_child(load)
      assert {:ok, nil} = ViewState.Compactions.get(key)
    end

    test "deletes loader", %{load: load, key: key} do
      assert_called Persist.Load.Supervisor.terminate_child(load)

      assert {:ok, nil} = ViewState.Loads.get(key)
      assert {:ok, nil} = ViewState.Destinations.get(key)
    end

    test "deletes source", %{load: %{source: source}, key: key} do
      assert_receive {:source_delete, ^source}, 1_000
      assert {:ok, nil} = ViewState.Sources.get(key)
    end

    test "deletes destination", %{load: %{destination: destination}, key: key} do
      assert_called Presto.Table.Destination.delete(destination)
      assert {:ok, nil} = ViewState.Destinations.get(key)
    end

    test "deletes transformation metadata", %{key: key} do
      assert {:ok, nil} = ViewState.Transformations.get(key)
    end
  end

  describe "handling #{dataset_delete()} event for non-existent load" do
    setup context do
      allow Persist.Compact.Supervisor.terminate_child(any()), return: :ok
      allow Presto.Table.Destination.delete(any()), return: :ok

      Brook.Test.with_event(@instance, fn ->
        ViewState.Sources.persist(context.key, context.load.source)
        ViewState.Destinations.persist(context.key, context.load.destination)
        ViewState.Transformations.persist(context.key, context.transform)
        ViewState.Compactions.persist(context.key, context.load)
      end)

      Brook.Test.send(@instance, dataset_delete(), "testing", context.delete)
    end

    test "deletes compactor", %{load: load, key: key} do
      assert_called Persist.Compact.Supervisor.terminate_child(load)
      assert {:ok, nil} = ViewState.Compactions.get(key)
    end

    test "deletes transformation metadata", %{key: key} do
      assert {:ok, nil} = ViewState.Transformations.get(key)
    end

    test "deletes source", %{load: %{source: source}, key: key} do
      assert_receive {:source_delete, ^source}, 1_000
      assert {:ok, nil} = ViewState.Sources.get(key)
    end

    test "deletes destination", %{load: %{destination: destination}, key: key} do
      assert_called Presto.Table.Destination.delete(destination)
      assert {:ok, nil} = ViewState.Destinations.get(key)
    end
  end
end

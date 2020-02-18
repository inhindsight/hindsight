defmodule Persist.Event.HandlerTest do
  use ExUnit.Case
  import Mox
  import AssertAsync
  require Temp.Env
  import Events, only: [transform_define: 0, compact_start: 0, compact_end: 0]

  @instance Persist.Application.instance()

  Temp.Env.modify([
    %{
      app: :service_persist,
      key: Persist.Compaction,
      set: [compactor: Persist.CompactorMock]
    }
  ])

  setup :set_mox_global

  test "persists transformation for dataset" do
    transform =
      Transform.new!(
        id: "transform-1",
        dataset_id: "ds1",
        subset_id: "sb1",
        dictionary: [
          Dictionary.Type.String.new!(name: "name"),
          Dictionary.Type.Integer.new!(name: "age")
        ],
        steps: [
          Transform.MoveField.new!(from: "name", to: "fullname")
        ]
      )

    Brook.Test.send(@instance, transform_define(), "testing", transform)

    assert {:ok, transform} ==
             Persist.Transformations.get(transform.dataset_id, transform.subset_id)
  end

  describe "compaction" do
    setup do
      load =
        Load.Persist.new!(
          id: "persist-1",
          dataset_id: "ds1",
          subset_id: "sb1",
          source: "topic-a",
          destination: "table_name"
        )

      [load: load]
    end

    test "persists and starts a compaction on #{compact_start()}", %{load: load} do
      test = self()

      Persist.CompactorMock
      |> stub(:compact, fn load ->
        send(test, {:compact, load})
        :ok
      end)

      Brook.Test.send(@instance, compact_start(), "testing", load)

      assert_receive {:compact, ^load}, 2_000
      assert true == Persist.Load.Store.is_being_compacted?(load)
      assert_receive {:brook_event, %Brook.Event{type: compact_end(), data: ^load}}
    end

    test "clears compaction mark on #{compact_end()}", %{load: load} do
      Brook.Test.with_event(@instance, fn ->
        Persist.Load.Store.persist(load)
        Persist.Load.Store.mark_for_compaction(load)
        Persist.Load.Store.mark_done(load)
      end)

      Brook.Test.send(@instance, compact_end(), "testing", load)

      assert_async do
        assert false == Persist.Load.Store.is_being_compacted?(load)
      end
    end
  end
end

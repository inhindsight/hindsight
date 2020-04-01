defmodule Persist.Event.HandlerTest do
  use ExUnit.Case
  import Mox
  import AssertAsync
  require Temp.Env
  import Events, only: [transform_define: 0, compact_start: 0, compact_end: 0]

  @instance Persist.Application.instance()

  Temp.Env.modify([
    %{
      app: :definition_presto,
      key: Presto.Table.Compactor,
      set: [impl: Persist.CompactorMock]
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
        Load.new!(
          id: "persist-1",
          dataset_id: "ds1",
          subset_id: "sb1",
          source: Source.Fake.new!(),
          destination: Presto.Table.new!(
            url: "http://localhost:8080",
            name: "table24"
          )
        )

      [load: load]
    end

    test "persists and starts a compaction on #{compact_start()}", %{load: %{destination: destination} = load} do
      test = self()

      Persist.CompactorMock
      |> stub(:compact, fn table ->
        send(test, {:compact, table})
        :ok
      end)

      Brook.Test.send(@instance, compact_start(), "testing", load)

      assert_receive {:compact, ^destination}, 2_000
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

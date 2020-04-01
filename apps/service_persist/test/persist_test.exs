defmodule PersistTest do
  use ExUnit.Case
  import AssertAsync
  import Events
  require Temp.Env
  use Placebo

  import Definition, only: [identifier: 1]

  @instance Persist.Application.instance()
  @moduletag capture_log: true

  setup do
    test = self()
    allow Destination.start_link(any(), any()), exec: fn table, context ->
      send(test, {:destination_start_link, table, context})
      {:ok, table}
    end

    allow Destination.write(any(), any()), exec: fn table, messages ->
      send(test, {:destination_write, table, messages})
      :ok
    end

    allow Destination.stop(any()), exec: fn table ->
      send(test, {:destination_stop, table})
      :ok
    end

    Brook.Test.clear_view_state(@instance, "transformations")

    on_exit(fn ->
      Persist.Load.Supervisor.kill_all_children()
    end)

    :ok
  end

  test "load:start starts writing to presto" do
    transform =
      Transform.new!(
        id: "transform-1",
        dataset_id: "ds1",
        subset_id: "example",
        dictionary: [
          %Dictionary.Type.String{name: "name"},
          %Dictionary.Type.Integer{name: "age"}
        ],
        steps: [
          Transform.MoveField.new!(from: "name", to: "fullname")
        ]
      )

    Brook.Test.with_event(@instance, fn ->
      Persist.Transformations.persist(transform)
    end)

    load =
      Load.new!(
        id: "persist-1",
        dataset_id: "ds1",
        subset_id: "example",
        source: Source.Fake.new!(),
        destination: Presto.Table.new!(
          url: "http://localhost:8080",
          name: "table_testing"
        )
      )

    Brook.Test.send(@instance, load_start(), "testing", load)

    assert_async max_tries: 20 do
      assert :undefined != Persist.Load.Registry.whereis(:"#{identifier(load)}")
    end

    messages = [
      %{"name" => "bob", "age" => 12}
    ]

    Source.Fake.inject_messages(load.source, messages)

    assert_receive {:destination_write, _, [%{"fullname" => "bob", "age" => 12}]}

    assert load == Persist.Load.Store.get!(load.dataset_id, load.subset_id)
  end

  test "load:end stops source and marks load as done" do

    transform =
      Transform.new!(
        id: "transform-1",
        dataset_id: "ds1",
        subset_id: "example",
        dictionary: [
          %Dictionary.Type.String{name: "name"},
          %Dictionary.Type.Integer{name: "age"}
        ],
        steps: []
      )

    Brook.Test.with_event(@instance, fn ->
      Persist.Transformations.persist(transform)
    end)

    load =
      Load.new!(
        id: "persist-1",
        dataset_id: "ds1",
        subset_id: "example",
        source: Source.Fake.new!(),
        destination: Presto.Table.new!(
          url: "http://localhost:8080",
          name: "table_b"
        )
      )

    Brook.Test.send(@instance, load_start(), "testing", load)

    assert_async max_tries: 40, debug: true do
      assert :undefined != Persist.Load.Registry.whereis(:"#{identifier(load)}")
    end

    Brook.Test.send(@instance, load_end(), "testing", load)

    assert_async max_tries: 20 do
      assert :undefined == Persist.Load.Registry.whereis(:"#{identifier(load)}")
    end

    assert true == Persist.Load.Store.done?(load)

    assert_receive {:brook_event, %Brook.Event{type: compact_start(), data: ^load}}
  end

  test "gracefully handles load:persist:end with no start" do
    load =
      Load.new!(
        id: "persist-1",
        dataset_id: "ds1",
        subset_id: "example",
        source: Source.Fake.new!(),
        destination: Presto.Table.new!(
          url: "http://localhost:8080",
          name: "table_c"
        )
      )

    Brook.Test.send(@instance, load_end(), "testing", load)
  end
end

defmodule PersistTest do
  use ExUnit.Case
  import Mox
  import AssertAsync
  import Events
  require Temp.Env

  import Definition, only: [identifier: 1]

  @instance Persist.Application.instance()
  @moduletag capture_log: true

  Temp.Env.modify([
    %{
      app: :service_persist,
      key: Persist.Loader,
      update: fn config ->
        Keyword.put(config, :writer, Writer.PrestoMock)
      end
    }
  ])

  setup :set_mox_global
  setup :verify_on_exit!

  setup do
    Brook.Test.clear_view_state(@instance, "transformations")

    on_exit(fn ->
      Persist.Load.Supervisor.kill_all_children()
    end)

    :ok
  end

  test "load:persist:start starts writing to presto" do
    test = self()

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

    {:ok, dictionary} = Transformer.transform_dictionary(transform.steps, transform.dictionary)

    Brook.Test.with_event(@instance, fn ->
      Persist.Transformations.persist(transform)
    end)

    load =
      Load.Persist.new!(
        id: "persist-1",
        dataset_id: "ds1",
        subset_id: "example",
        source: Source.Fake.new(),
        destination: "ds1_example"
      )

    Writer.PrestoMock
    |> stub(:start_link, fn _args -> {:ok, :writer_presto_pid} end)
    |> stub(:write, fn :writer_presto_pid, msgs, opts ->
      send(test, {:write, msgs, opts})
      :ok
    end)

    Brook.Test.send(@instance, load_persist_start(), "testing", load)

    assert_async max_tries: 20 do
      assert :undefined != Persist.Load.Registry.whereis(:"#{identifier(load)}")
    end

    messages = [
      %{"name" => "bob", "age" => 12}
    ]

    Source.Fake.inject_messages(load.source, messages)

    assert_receive {:write, [%{"fullname" => "bob", "age" => 12}], [dictionary: ^dictionary]}

    assert load == Persist.Load.Store.get!(load.dataset_id, load.subset_id)
  end

  test "load:persist:end stops source and marks load as done" do
    test = self()

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
      Load.Persist.new!(
        id: "persist-1",
        dataset_id: "ds1",
        subset_id: "example",
        source: Source.Fake.new(),
        destination: "ds1_example"
      )

    Writer.PrestoMock
    |> stub(:start_link, fn _args -> {:ok, :writer_presto_pid} end)
    |> stub(:write, fn :writer_presto_pid, msgs, _opts ->
      send(test, {:write, msgs})
      :ok
    end)

    Brook.Test.send(@instance, load_persist_start(), "testing", load)

    assert_async max_tries: 40, debug: true do
      assert :undefined != Persist.Load.Registry.whereis(:"#{identifier(load)}")
    end

    Brook.Test.send(@instance, load_persist_end(), "testing", load)

    assert_async max_tries: 20 do
      assert :undefined == Persist.Load.Registry.whereis(:"#{identifier(load)}")
    end

    assert true == Persist.Load.Store.done?(load)

    assert_receive {:brook_event, %Brook.Event{type: compact_start(), data: ^load}}
  end

  test "gracefully handles load:persist:end with no start" do
    load =
      Load.Persist.new!(
        id: "persist-1",
        dataset_id: "ds1",
        subset_id: "example",
        source: Source.Fake.new(),
        destination: "ds1_example"
      )

    Brook.Test.send(@instance, load_persist_end(), "testing", load)
  end
end

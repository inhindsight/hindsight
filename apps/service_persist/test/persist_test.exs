defmodule PersistTest do
  use ExUnit.Case
  import Mox
  import AssertAsync
  import Events
  require Temp.Env

  @instance Persist.Application.instance()
  @moduletag capture_log: true

  Temp.Env.modify([
    %{
      app: :service_persist,
      key: Persist.Load.Broadway,
      update: fn config ->
        Keyword.put(config, :dlq, Persist.DLQMock)
      end
    },
    %{
      app: :service_persist,
      key: Persist.Writer,
      update: fn config ->
        Keyword.put(config, :writer, Writer.PrestoMock)
      end
    }
  ])

  setup :set_mox_global
  setup :verify_on_exit!

  setup do
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
        dictionary: [
          %Dictionary.Type.String{name: "name"},
          %Dictionary.Type.Integer{name: "age"}
        ],
        steps: [
          Transformer.MoveField.new!(from: "name", to: "fullname")
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
        name: "example",
        source: "topic-example",
        destination: "ds1_example",
        schema: [
          %Dictionary.Type.String{name: "name"},
          %Dictionary.Type.Integer{name: "age"}
        ]
      )

    Writer.PrestoMock
    |> stub(:start_link, fn _args -> {:ok, :writer_presto_pid} end)
    |> stub(:write, fn :writer_presto_pid, msgs, opts ->
      send(test, {:write, msgs, opts})
      :ok
    end)

    Brook.Test.send(@instance, load_persist_start(), "testing", load)

    assert_async max_tries: 20 do
      assert :undefined != Persist.Load.Registry.whereis(:"#{load.source}")
    end

    broadway = Process.whereis(:"persist_broadway_#{load.source}")

    messages = [
      %{value: %{"name" => "bob", "age" => 12} |> Jason.encode!()}
    ]

    ref = Broadway.test_messages(broadway, messages)

    assert_receive {:write, [[12, "'bob'"]], [dictionary: ^dictionary]}
    assert_receive {:ack, ^ref, success, failed}
    assert 1 == length(success)

    assert load == Persist.Load.Store.get!(load.id)
  end

  test "load:persist:end stops broadway and clears viewstate" do
    test = self()

    load =
      Load.Persist.new!(
        id: "persist-1",
        dataset_id: "ds1",
        name: "example",
        source: "topic-example",
        destination: "ds1_example",
        schema: [
          %Dictionary.Type.String{name: "name"},
          %Dictionary.Type.Integer{name: "age"}
        ]
      )

    Writer.PrestoMock
    |> stub(:start_link, fn _args -> {:ok, :writer_presto_pid} end)
    |> stub(:write, fn :writer_presto_pid, msgs, _opts ->
      send(test, {:write, msgs})
      :ok
    end)

    Brook.Test.send(@instance, load_persist_start(), "testing", load)

    assert_async max_tries: 40 do
      assert :undefined != Persist.Load.Registry.whereis(:"#{load.source}")
    end

    Brook.Test.send(@instance, load_persist_end(), "testing", load)

    assert_async max_tries: 20 do
      assert :undefined == Persist.Load.Registry.whereis(:"#{load.source}")
    end

    assert nil == Persist.Load.Store.get!(load.id)
  end

  test "gracefully handles load:persist:end with no start" do
    load =
      Load.Persist.new!(
        id: "persist-1",
        dataset_id: "ds1",
        name: "example",
        source: "topic-example",
        destination: "ds1_example",
        schema: [
          %Dictionary.Type.String{name: "name"},
          %Dictionary.Type.Integer{name: "age"}
        ]
      )

    Brook.Test.send(@instance, load_persist_end(), "testing", load)
  end
end

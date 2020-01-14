defmodule PersistTest do
  use ExUnit.Case
  import Mox
  import AssertAsync

  import Definition.Events

  @instance Persist.Application.instance()
  @moduletag capture_log: true

  setup :set_mox_global
  setup :verify_on_exit!

  setup do
    on_exit(fn ->
      Persist.Load.Supervisor.kill_all_children()
    end)

    :ok
  end

  test "load:pesist:start starts writing to presto" do
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

    Persist.WriterMock
    |> expect(:start_link, fn args ->
      send(test, {:start_link, args})
      {:ok, :writer_pid}
    end)
    |> expect(:write, fn :writer_pid, messages ->
      send(test, {:write, messages})
      :ok
    end)

    Brook.Test.send(@instance, load_persist_start(), "testing", load)

    assert_async max_tries: 50 do
      assert :undefined != Persist.Load.Registry.whereis(:"#{load.source}")
    end

    broadway = Persist.Load.Registry.whereis(:"#{load.source}")

    messages = [
      %{value: %{"one" => 1} |> Jason.encode!()}
    ]

    ref = Broadway.test_messages(broadway, messages)

    assert_receive {:write, [%{"one" => 1}]}
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

    Persist.WriterMock
    |> expect(:start_link, fn args ->
      send(test, {:start_link, args})
      {:ok, :writer_pid}
    end)

    Brook.Test.send(@instance, load_persist_start(), "testing", load)

    assert_async do
      assert :undefined != Persist.Load.Registry.whereis(:"#{load.source}")
    end

    Brook.Test.send(@instance, load_persist_end(), "testing", load)

    assert_async do
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

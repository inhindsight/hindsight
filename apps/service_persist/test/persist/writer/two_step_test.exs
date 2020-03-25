defmodule Persist.Writer.TwoStepTest do
  use ExUnit.Case
  require Temp.Env
  import Mox

  setup :set_mox_global

  Temp.Env.modify([
    %{
      app: :service_persist,
      key: Persist.Writer.TwoStep,
      set: [
        writer: Persist.WriterMock,
        staged_batches_count: 1
      ]
    },
    %{
      app: :service_persist,
      key: Persist.TableManager,
      set: [
        impl: Persist.TableManagerMock
      ]
    },
    %{
      app: :service_persist,
      key: Persist.DataStorage,
      set: [
        impl: Persist.DataStorageMock
      ]
    }
  ])

  setup do
    load =
      Load.Persist.new!(
        id: "persist-1",
        dataset_id: "ds1",
        subset_id: "sb1",
        source: Source.Fake.new(),
        destination: "table_a"
      )

    dictionary =
      Dictionary.from_list([
        Dictionary.Type.String.new!(name: "name"),
        Dictionary.Type.Integer.new!(name: "age")
      ])

    test = self()

    Persist.TableManagerMock
    |> stub(:create, fn table, dictionary, format ->
      send(test, {:create_table, table, dictionary, format})
      :ok
    end)
    |> stub(:copy, fn from, to ->
      send(test, {:copy, from, to})
      {:ok, :result}
    end)

    Persist.WriterMock
    |> stub(:start_link, fn opts ->
      send(test, {:writer_start_link, opts})
      {:ok, :writer_pid}
    end)
    |> stub(:write, fn server, messages, opts ->
      send(test, {:write, server, messages, opts})
      :ok
    end)

    Persist.DataStorageMock
    |> stub(:delete, fn path ->
      send(test, {:data_storage_delete, path})
      :ok
    end)

    [load: load, dictionary: dictionary]
  end

  test "two step will create production ORC table", %{load: load, dictionary: dictionary} do
    start_supervised({Persist.Writer.TwoStep, load: load, dictionary: dictionary})

    assert_receive {:create_table, "table_a", ^dictionary, "ORC"}
  end

  test "two step start sub writer with proper arguments", %{load: load, dictionary: dictionary} do
    start_supervised({Persist.Writer.TwoStep, load: load, dictionary: dictionary})

    updated_load = %{load | destination: "table_a__staging"}
    assert_receive {:writer_start_link, [load: ^updated_load, dictionary: ^dictionary]}
  end

  test "two step will delegate to subwriter and then copy data over and delete", %{
    load: load,
    dictionary: dictionary
  } do
    messages = [%{"name" => "brian", "age" => 38}]

    {:ok, pid} = start_supervised({Persist.Writer.TwoStep, load: load, dictionary: dictionary})
    assert :ok == Persist.Writer.TwoStep.write(pid, messages)

    assert_receive {:write, :writer_pid, ^messages, _}
    assert_receive {:copy, "table_a__staging", "table_a"}
    assert_receive {:data_storage_delete, "table_a__staging"}
  end
end

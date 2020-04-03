defmodule Presto.Table.DestinationTest do
  use ExUnit.Case
  require Temp.Env
  import Mox

  setup :set_mox_global

  Temp.Env.modify([
    %{
      app: :definition_presto,
      key: Presto.Table.Destination,
      set: [
        catalog: "hive",
        user: "testing"
      ]
    },
    %{
      app: :definition_presto,
      key: Presto.Table.Manager,
      set: [
        impl: Presto.Table.ManagerMock
      ]
    }
  ])

  setup do
    Process.flag(:trap_exit, true)
    test = self()

    Presto.Table.ManagerMock
    |> stub(:create, fn session, name, dictionary, format ->
      send(test, {:create_table, session, name, dictionary, format})
      :ok
    end)
    |> stub(:create_from, fn session, from, to, format, with_data ->
      send(test, {:create_from, session, from, to, format, with_data})
      {:ok, 0}
    end)

    dictionary =
      Dictionary.from_list([
        Dictionary.Type.String.new!(name: "name"),
        Dictionary.Type.Integer.new!(name: "age"),
        Dictionary.Type.Date.new!(name: "birthdate", format: "%Y")
      ])

    destination =
      Presto.Table.new!(
        url: "http://localhost:8080",
        name: "table1"
      )

    context =
      Destination.Context.new!(
        dictionary: dictionary,
        app_name: "testing",
        dataset_id: "ds1",
        subset_id: "default"
      )

    [destination: destination, context: context]
  end

  test "stop will stop the process", %{destination: destination, context: context} do
    assert {:ok, pid} = Destination.start_link(destination, context)
    assert Process.alive?(pid)

    assert :ok = Destination.stop(destination, pid)
    refute Process.alive?(pid)
  end
end

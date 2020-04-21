defmodule PersistTest do
  use ExUnit.Case
  use Placebo
  require Temp.Env
  import AssertAsync
  import Events
  import Definition, only: [identifier: 1]
  alias Persist.ViewState

  @instance Persist.Application.instance()
  @moduletag capture_log: true

  setup do
    on_exit(fn ->
      Persist.Load.Supervisor.kill_all_children()

      ["Loads", "Transformations", "Compactions", "Sources", "Destinations"]
      |> Enum.map(fn state -> :"Elixir.Persist.ViewState.#{state}" end)
      |> Enum.each(&Brook.Test.clear_view_state(@instance, &1.collection()))
    end)

    test = self()

    allow Destination.start_link(any(), any()),
      exec: fn table, context ->
        send(test, {:destination_start_link, table, context})
        {:ok, table}
      end

    allow Destination.write(any(), any(), any()),
      exec: fn table, pid, messages ->
        send(test, {:destination_write, table, pid, messages})
        :ok
      end

    allow Destination.stop(any(), any()),
      exec: fn table, pid ->
        send(test, {:destination_stop, table, pid})
        :ok
      end

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

    load =
      Load.new!(
        id: "persist-1",
        dataset_id: "ds1",
        subset_id: "example",
        source: Source.Fake.new!(),
        destination:
          Presto.Table.new!(
            url: "http://localhost:8080",
            name: "table_testing"
          )
      )

    Brook.Test.with_event(@instance, fn ->
      identifier(transform)
      |> ViewState.Transformations.persist(transform)
    end)

    [load: load, key: identifier(load)]
  end

  test "load:start starts writing to presto", %{load: load, key: key} do
    Brook.Test.send(@instance, load_start(), "testing", load)

    assert_async max_tries: 20 do
      assert :undefined != Persist.Load.Registry.whereis(:"#{key}")
    end

    messages = [
      %{"name" => "bob", "age" => 12}
    ]

    Source.Fake.inject_messages(load.source, messages)

    assert_receive {:destination_write, _, _, [%{"fullname" => "bob", "age" => 12}]}

    assert {:ok, ^load} = ViewState.Loads.get(key)
  end

  test "load:end stops source and removes load from state", %{load: load, key: key} do
    Brook.Test.send(@instance, load_start(), "testing", load)

    assert_async max_tries: 40, debug: true do
      assert :undefined != Persist.Load.Registry.whereis(:"#{key}")
    end

    Brook.Test.send(@instance, load_end(), "testing", load)

    assert_async max_tries: 20 do
      assert :undefined == Persist.Load.Registry.whereis(:"#{key}")
    end

    assert {:ok, nil} = ViewState.Loads.get(key)

    assert_receive {:brook_event, %Brook.Event{type: compact_start(), data: ^load}}
  end

  test "gracefully handles load:end with no start", %{load: load, key: key} do
    Brook.Test.send(@instance, load_end(), "testing", load)
    assert {:ok, nil} = ViewState.Loads.get(key)
  end
end

defmodule Acquire.Event.HandlerTest do
  use ExUnit.Case
  import Events, only: [transform_define: 0, load_start: 0, dataset_delete: 0]
  import Definition, only: [identifier: 1]
  alias Acquire.ViewState

  @instance Acquire.Application.instance()

  setup do
    on_exit(fn ->
      Brook.Test.clear_view_state(@instance, ViewState.Fields.collection())
      Brook.Test.clear_view_state(@instance, ViewState.Fields.collection())
    end)

    load =
      Load.new!(
        id: "load-1",
        dataset_id: "ds1",
        subset_id: "sb1",
        source: Source.Fake.new!(),
        destination: Presto.Table.new!(url: "http://localhost:8080", name: "table_name")
      )

    transform =
      Transform.new!(
        id: "transform-1",
        dataset_id: load.dataset_id,
        subset_id: load.subset_id,
        dictionary: Dictionary.from_list([Dictionary.Type.String.new!(name: "foo")]),
        steps: [Transform.MoveField.new!(from: "foo", to: "bar")]
      )

    [load: load, transform: transform, key: identifier(load)]
  end

  describe "handling #{load_start()} event" do
    test "persists destination", %{load: load, key: key} do
      Brook.Test.send(@instance, load_start(), "testing", load)
      assert ViewState.Destinations.get(key) == {:ok, load.destination}
    end
  end

  describe "handling #{transform_define()} event" do
    test "persists transformed dictionary", %{transform: transform, key: key} do
      {:ok, dictionary} = Transformer.transform_dictionary(transform.steps, transform.dictionary)
      Brook.Test.send(@instance, transform_define(), "testing", transform)
      assert ViewState.Fields.get(key) == {:ok, dictionary}
    end
  end

  describe "handling #{dataset_delete()} event" do
    setup context do
      Brook.Test.with_event(@instance, fn ->
        ViewState.Fields.persist(context.key, context.transform.dictionary)
        ViewState.Destinations.persist(context.key, context.load.destination)
      end)

      delete =
        Delete.new!(
          id: "delete-1",
          dataset_id: context.load.dataset_id,
          subset_id: context.load.subset_id
        )

      Brook.Test.send(@instance, dataset_delete(), "testing", delete)
    end

    test "removes destination from state", %{key: key} do
      assert ViewState.Destinations.get(key) == {:ok, nil}
    end

    test "removes fields from state", %{key: key} do
      assert ViewState.Fields.get(key) == {:ok, nil}
    end
  end
end

defmodule Define.StoreTest do
  use ExUnit.Case

  @instance Define.Application.instance()

  describe "update_definition/1" do
    test "persists a new extract" do
      id = "adataset"

      Brook.Test.with_event(@instance, fn ->
        event =
          Extract.new!(
            id: "extract-1",
            dataset_id: id,
            subset_id: "default",
            destination: "success",
            dictionary: [],
            steps: []
          )

        Define.Store.update_definition(event)
      end)

      persisted = Define.Store.get(id)

      expected = %Define.DataDefinition{
        dataset_id: id,
        extract_destination: "success",
        extract_steps: [],
        dictionary: %Dictionary.Impl{by_name: %{}, by_type: %{}, ordered: [], size: 0},
        subset_id: "default",
        version: 1
      }

      assert ^expected = persisted
    end

    test "persists a new transform" do
      id = "a"

      Brook.Test.with_event(@instance, fn ->
        event =
          Transform.new!(
            id: "transform-1",
            dataset_id: id,
            subset_id: "default",
            dictionary: [],
            steps: []
          )

        Define.Store.update_definition(event)
      end)

      persisted = Define.Store.get(id)

      expected = %Define.DataDefinition{
        dataset_id: id,
        dictionary: %Dictionary.Impl{by_name: %{}, by_type: %{}, ordered: [], size: 0},
        subset_id: "default",
        version: 1
      }

      assert ^expected = persisted
    end
  end

  test "persists a new persist" do
    id = "bdataset"

    Brook.Test.with_event(@instance, fn ->
      event =
        Load.Persist.new!(
          id: "persist-1",
          dataset_id: id,
          subset_id: "default",
          source: "akafkatopic",
          destination: "storage__json"
        )

      Define.Store.update_definition(event)
    end)

    persisted = Define.Store.get(id)

    expected = %Define.DataDefinition{
      dataset_id: id,
      persist_source: "akafkatopic",
      persist_destination: "storage__json",
      subset_id: "default",
      version: 1
    }

    assert ^expected = persisted
  end
end

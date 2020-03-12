defmodule Define.StoreTest do
  use ExUnit.Case

  @instance Define.Application.instance()

  describe "update_definition/1" do
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
        dataset_id: "a",
        dictionary: %Dictionary.Impl{by_name: %{}, by_type: %{}, ordered: [], size: 0},
        subset_id: "default",
        version: 1
      }

      assert ^expected = persisted
    end
  end
end

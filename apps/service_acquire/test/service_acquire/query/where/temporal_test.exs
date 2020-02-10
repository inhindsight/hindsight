defmodule Acquire.Query.Where.TemporalTest do
  use ExUnit.Case

  alias Acquire.Query.Where.Temporal
  alias Acquire.Queryable

  @instance Acquire.Application.instance()

  setup do
    Brook.Test.clear_view_state(@instance, "fields")

    :ok
  end

  describe "single timestamp field in dictionary" do
    setup do
      Brook.Test.with_event(@instance, fn ->
        Acquire.Dictionaries.persist(
          Transform.new!(
            id: "transform-1",
            dataset_id: "ds1",
            subset_id: "sb1",
            dictionary: [
              Dictionary.Type.Timestamp.new!(name: "__timestamp__", format: "%Y")
            ],
            steps: []
          )
        )
      end)
    end

    test "will look for rows that are after parameter" do
      result = Temporal.to_queryable("ds1", "sb1", "2020-01-01T00:00:00", "")

      assert Queryable.parse_statement(result) ==
               "date_diff('millisecond', __timestamp__, date_parse(?, '%Y-%m-%dT%H:%i:%S')) > 0"

      assert Queryable.parse_input(result) == ["2020-01-01T00:00:00"]
    end

    test "will look for rows that are before parameter" do
      result = Temporal.to_queryable("ds1", "sb1", "", "2020-01-01T00:00:00")

      assert Queryable.parse_statement(result) ==
               "date_diff('millisecond', __timestamp__, date_parse(?, '%Y-%m-%dT%H:%i:%S')) < 0"

      assert Queryable.parse_input(result) == ["2020-01-01T00:00:00"]
    end

    test "will look for rows between parameters" do
      result = Temporal.to_queryable("ds1", "sb1", "2018-01-01T00:00:00", "2020-01-01T00:00:00")

      assert Queryable.parse_statement(result) ==
               "(date_diff('millisecond', __timestamp__, date_parse(?, '%Y-%m-%dT%H:%i:%S')) > 0 AND date_diff('millisecond', __timestamp__, date_parse(?, '%Y-%m-%dT%H:%i:%S')) < 0)"

      assert Queryable.parse_input(result) == ["2018-01-01T00:00:00", "2020-01-01T00:00:00"]
    end

    test "will return empty list when no times given" do
      result = Temporal.to_queryable("ds1", "sb1", "", "")
      assert result == nil
    end
  end

  describe "more than one timestamp field" do
    setup do
      Brook.Test.with_event(@instance, fn ->
        Acquire.Dictionaries.persist(
          Transform.new!(
            id: "transform-1",
            dataset_id: "ds1",
            subset_id: "sb1",
            dictionary: [
              Dictionary.Type.Timestamp.new!(name: "__timestamp__", format: "%Y"),
              Dictionary.Type.Map.new!(
                name: "map",
                dictionary: [
                  Dictionary.Type.Timestamp.new!(name: "__timestamp__", format: "%Y")
                ]
              )
            ],
            steps: []
          )
        )
      end)
    end

    test "will or together date queries" do
      result = Temporal.to_queryable("ds1", "sb1", "2018-01-01T00:00:00", "2020-01-01T00:00:00")

      assert Queryable.parse_statement(result) ==
               "((date_diff('millisecond', __timestamp__, date_parse(?, '%Y-%m-%dT%H:%i:%S')) > 0 AND date_diff('millisecond', __timestamp__, date_parse(?, '%Y-%m-%dT%H:%i:%S')) < 0) OR (date_diff('millisecond', map.__timestamp__, date_parse(?, '%Y-%m-%dT%H:%i:%S')) > 0 AND date_diff('millisecond', map.__timestamp__, date_parse(?, '%Y-%m-%dT%H:%i:%S')) < 0))"

      assert Queryable.parse_input(result) == [
               "2018-01-01T00:00:00",
               "2020-01-01T00:00:00",
               "2018-01-01T00:00:00",
               "2020-01-01T00:00:00"
             ]
    end
  end

  test "will return an error tuple if no dictionary available" do
    assert {:error, "dictionary not found for ds1 sb1"} =
             Temporal.to_queryable("ds1", "sb1", "2018-01-01T00:00:00", "2020-01-01T00:00:00")
  end
end

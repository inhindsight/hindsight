defmodule Acquire.Query.Where.TemporalTest do
  use ExUnit.Case
  import Definition, only: [identifier: 1]
  alias Acquire.Query.Where.Temporal
  alias Acquire.Queryable

  @instance Acquire.Application.instance()

  setup do
    on_exit(fn ->
      Brook.Test.clear_view_state(@instance, Acquire.ViewState.Fields.collection())
      Brook.Test.clear_view_state(@instance, Acquire.ViewState.Destinations.collection())
    end)
  end

  describe "single timestamp field in dictionary" do
    setup do
      Brook.Test.with_event(@instance, fn ->
        transform =
          Transform.new!(
            id: "transform-1",
            dataset_id: "ds1",
            subset_id: "sb1",
            dictionary: [
              Dictionary.Type.Timestamp.new!(name: "__timestamp__", format: "%Y")
            ],
            steps: []
          )

        {:ok, dict} = Transformer.transform_dictionary(transform.steps, transform.dictionary)

        identifier(transform)
        |> Acquire.ViewState.Fields.persist(dict)
      end)
    end

    test "will look for rows that are after parameter" do
      result = Temporal.to_queryable("ds1", "sb1", "2020-01-01T00:00:00", "")

      assert Queryable.parse_statement(result) ==
               "date_diff('millisecond', date_parse(?, '%Y-%m-%dT%H:%i:%S'), __timestamp__) > 0"

      assert Queryable.parse_input(result) == ["2020-01-01T00:00:00"]
    end

    test "will look for rows that are before parameter" do
      result = Temporal.to_queryable("ds1", "sb1", "", "2020-01-01T00:00:00")

      assert Queryable.parse_statement(result) ==
               "date_diff('millisecond', date_parse(?, '%Y-%m-%dT%H:%i:%S'), __timestamp__) < 0"

      assert Queryable.parse_input(result) == ["2020-01-01T00:00:00"]
    end

    test "will look for rows between parameters" do
      result = Temporal.to_queryable("ds1", "sb1", "2018-01-01T00:00:00", "2020-01-01T00:00:00")

      assert Queryable.parse_statement(result) ==
               "(date_diff('millisecond', date_parse(?, '%Y-%m-%dT%H:%i:%S'), __timestamp__) > 0 AND date_diff('millisecond', date_parse(?, '%Y-%m-%dT%H:%i:%S'), __timestamp__) < 0)"

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
        transform =
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

        {:ok, dict} = Transformer.transform_dictionary(transform.steps, transform.dictionary)

        identifier(transform)
        |> Acquire.ViewState.Fields.persist(dict)
      end)
    end

    test "will or together date queries" do
      result = Temporal.to_queryable("ds1", "sb1", "2018-01-01T00:00:00", "2020-01-01T00:00:00")

      assert Queryable.parse_statement(result) ==
               "((date_diff('millisecond', date_parse(?, '%Y-%m-%dT%H:%i:%S'), __timestamp__) > 0 AND date_diff('millisecond', date_parse(?, '%Y-%m-%dT%H:%i:%S'), __timestamp__) < 0) OR (date_diff('millisecond', date_parse(?, '%Y-%m-%dT%H:%i:%S'), map.__timestamp__) > 0 AND date_diff('millisecond', date_parse(?, '%Y-%m-%dT%H:%i:%S'), map.__timestamp__) < 0))"

      assert Queryable.parse_input(result) == [
               "2018-01-01T00:00:00",
               "2020-01-01T00:00:00",
               "2018-01-01T00:00:00",
               "2020-01-01T00:00:00"
             ]
    end
  end

  test "will return an error tuple if no dictionary available" do
    assert {:error, "dictionary not found for ds1__sb1"} =
             Temporal.to_queryable("ds1", "sb1", "2018-01-01T00:00:00", "2020-01-01T00:00:00")
  end
end

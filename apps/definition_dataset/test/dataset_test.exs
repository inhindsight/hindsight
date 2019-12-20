defmodule DatasetTest do
  use ExUnit.Case
  import Checkov
  doctest Dataset

  describe "new/1" do
    data_test "validates #{inspect(field)} against bad input" do
      {:ok, input} =
        DefinitionFaker.dataset(%{})
        |> Ok.map(&Map.delete(&1, :__struct__))
        |> Ok.map(&put_in(&1, field, value))

      assert {:error, [%{input: value, path: field} | _]} = Dataset.new(input)

      where [
        [:field, :value],
        [[:version], "1"],
        [[:id], ""],
        [[:owner_id], 42],
        [[:title], " "],
        [[:description], 9001],
        [[:keywords], 99],
        [[:license], ""],
        [[:created_ts], ""],
        [[:profile, :updated_ts], "bar"],
        [[:profile, :profiled_ts], "foo"],
        [[:profile, :modified_ts], "bar"],
        [[:profile, :spatial], [[]]],
        [[:profile, :temporal], ["foo", "bar"]]
      ]
    end

    data_test "accepts default value in #{inspect(field)} field" do
      {:ok, input} =
        DefinitionFaker.dataset(%{})
        |> Ok.map(&Map.delete(&1, :__struct__))
        |> Ok.map(&put_in(&1, field, value))

      assert {:ok, %Dataset{}} = Dataset.new(input)

      where [
        [:field, :value],
        [[:description], ""],
        [[:keywords], []],
        [[:profile, :updated_ts], ""],
        [[:profile, :profiled_ts], ""],
        [[:profile, :modified_ts], ""],
        [[:profile, :spatial], []],
        [[:profile, :temporal], []]
      ]
    end
  end
end

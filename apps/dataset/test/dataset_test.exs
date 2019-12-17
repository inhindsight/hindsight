defmodule DatasetTest do
  use ExUnit.Case
  import Checkov
  doctest Dataset

  describe "new/1" do
    test "handles input with string keys" do
      {:ok, ds} = DatasetFaker.dataset(%{})
      input = for {key, val} <- Map.delete(ds, :__struct__), do: {to_string(key), val}, into: %{}
      assert {:ok, %Dataset{}} = Dataset.new(input)
    end

    data_test "validates #{inspect(field)} against bad input" do
      {:ok, ds} = DatasetFaker.dataset(%{})
      input = Map.delete(ds, :__struct__) |> put_in(field, value)

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
      {:ok, ds} = DatasetFaker.dataset(%{})
      input = Map.delete(ds, :__struct__) |> put_in(field, value)

      assert {:ok, %Dataset{}} = Dataset.new(input)

      where [
        [:field, :value],
        [[:description], ""],
        [[:keywords], []],
        [[:profile, :updated_ts], ""],
        [[:profile, :profiled_ts], ""],
        [[:profile, :modified_ts], ""],
        [[:profile, :spatial], []],
        [[:profile, :temporal], []],
      ]
    end
  end
end

defmodule DatasetTest do
  use ExUnit.Case
  import Checkov
  doctest Dataset

  describe "new/1" do
    test "returns a Dataset struct" do
      {:ok, ds} = DatasetFaker.dataset(%{})
      input = Map.delete(ds, :__struct__)
      assert {:ok, %Dataset{}} = Dataset.new(input)
    end

    data_test "validates #{inspect(field)} for bad input" do
      {:ok, ds} = DatasetFaker.dataset(%{})
      input = Map.delete(ds, :__struct__) |> put_in(field, value)

      assert {:error, [%{path: field}]} = Dataset.new(input)

      where [
        [:field, :value],
        [[:version], "1"],
        [[:id], ""],
        [[:org_id], 42],
        [[:title], " "],
        [[:description], 9001],
        [[:keywords], 99],
        [[:license], ""],
        [[:created_ts], "foo"],
        [[:modified_ts], "foo"],
        [[:contact, :name], 1],
        [[:contact, :email], "foo"],
        [[:boundaries, :spatial], [[]]],
        [[:boundaries, :temporal], ["foo"]],
        [[:data], nil]
      ]
    end
  end
end

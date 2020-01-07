defmodule DatasetTest do
  use ExUnit.Case
  import Checkov
  doctest Dataset

  describe "new/1" do
    data_test "validates #{inspect(field)} against bad input" do
      input = put_in(%{profile: %{}}, field, value)
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
  end
end

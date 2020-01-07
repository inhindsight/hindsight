defmodule Dataset.OwnerTest do
  use ExUnit.Case
  import Checkov
  doctest Dataset.Owner

  alias Dataset.Owner

  describe "new/1" do
    data_test "validates #{inspect(field)} against bad input" do
      input = put_in(%{contact: %{}}, field, value)
      assert {:error, [%{input: value, path: field} | _]} = Owner.new(input)

      where [
        [:field, :value],
        [[:version], "1"],
        [[:id], ""],
        [[:name], ""],
        [[:title], ""],
        [[:description], 123],
        [[:url], []],
        [[:image], nil],
        [[:contact, :name], nil],
        [[:contact, :email], "foo.com"]
      ]
    end
  end
end

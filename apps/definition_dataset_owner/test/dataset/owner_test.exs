defmodule Dataset.OwnerTest do
  use ExUnit.Case
  import Checkov
  doctest Dataset.Owner

  alias Dataset.Owner

  describe "new/1" do
    data_test "validates #{inspect(field)} against bad input" do
      {:ok, owner} = DefinitionFaker.owner(%{})
      input = Map.delete(owner, :__struct__) |> put_in(field, value)

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

    data_test "accepts default value in #{inspect(field)} field" do
      {:ok, owner} = DefinitionFaker.owner(%{})
      input = Map.delete(owner, :__struct__) |> put_in(field, value)

      assert {:ok, %Owner{}} = Owner.new(input)

      where [
        [:field, :value],
        [[:description], ""],
        [[:url], ""],
        [[:image], ""]
      ]
    end
  end
end

defmodule ExtractTest do
  use Checkov

  describe "new/1" do
    data_test "validates #{field} against bad input" do
      {:ok, input} =
        DefinitionFaker.extract(%{})
        |> Ok.map(&Map.delete(&1, :__struct__))
        |> Ok.map(&put_in(&1, [field], value))

      assert {:error, [%{input: value, path: [field]} | _]} = Extract.new(input)

      where [
        [:field, :value],
        [:version, "1"],
        [:id, ""],
        [:dataset_id, 2001],
        [:steps, 1]
      ]
    end
  end
end

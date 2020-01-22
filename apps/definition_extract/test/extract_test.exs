defmodule ExtractTest do
  use Checkov

  describe "new/1" do
    data_test "validates #{field} against bad input" do
      input = put_in(%{}, [field], value)
      assert {:error, [%{input: value, path: [field]} | _]} = Extract.new(input)

      where [
        [:field, :value],
        [:version, "1"],
        [:id, ""],
        [:dataset_id, 2001],
        [:steps, 1],
        [:steps, nil],
        [:dictionary, 1],
        [:dictionary, nil],
        [:name, nil],
        [:name, ""],
        [:destination, nil],
        [:destination, ""]
      ]
    end
  end
end

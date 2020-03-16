defmodule DeleteTest do
  use Checkov
  doctest Delete

  describe "new/1" do
    data_test "validates #{field} against bad input" do
      input = put_in(%{}, [field], value)
      assert {:error, [%{input: value, path: [field]} | _]} = Delete.new(input)

      where([
        [:field, :value],
        [:version, "1"],
        [:id, ""],
        [:dataset_id, 2001]
      ])
    end
  end
end

defmodule TransformTest do
  use Checkov
  doctest Transform

  describe "new/1" do
    data_test "validates #{field} against bad input" do
      input = put_in(%{}, [field], value)

      assert {:error, [%{input: value, path: [field]} | _]} = Transform.new(input)

      where [
        [:field, :value],
        [:version, "1"],
        [:id, ""],
        [:dataset_id, nil],
        [:dictionary, nil],
        [:steps, nil],
      ]
    end
  end
end

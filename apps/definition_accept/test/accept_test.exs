defmodule AcceptTest do
  use Checkov
  doctest Accept

  describe "new/1" do
    data_test "validates #{field} against bad input" do
      input = put_in(%{}, [field], value)
      assert {:error, [%{input: value, path: [field]} | _]} = Accept.new(input)

      where([
        [:field, :value],
        [:version, "1"],
        [:id, ""],
        [:dataset_id, 2001],
        [:name, nil],
        [:name, ""],
        [:destination, nil],
        [:destination, ""],
        [:batch_size, "100"],
        [:batch_size, nil],
        [:timeout, "10_000"],
        [:timeout, nil]
      ])
    end
  end
end

defmodule DataTest do
  use Checkov
  doctest Data

  describe "new/1" do
    data_test "validates #{inspect(field)} against bad input" do
      input = put_in(%{}, [field], value)
      assert {:error, [%{input: value, path: field} | _]} = Data.new(input)

      where [
        [:field, :value],
        [:version, -1],
        [:extract_id, ""],
        [:payload, []]
      ]
    end
  end
end

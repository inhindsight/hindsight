defmodule Load.BroadcastTest do
  use ExUnit.Case
  import Checkov

  describe "new/1" do
    data_test "validates #{field} against bad input" do
      input = put_in(%{}, [field], value)
      assert {:error, [%{input: value, path: [field]} | _]} = Load.Broadcast.new(input)

      where [
        [:field, :value],
        [:version, "1"],
        [:id, ""],
        [:id, nil],
        [:dataset_id, ""],
        [:dataset_id, nil],
        [:name, nil],
        [:source, nil],
        [:source, ""],
        [:destination, nil],
        [:destination, ""]
      ]
    end
  end
end

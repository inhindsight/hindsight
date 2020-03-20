defmodule Profile.UpdateTest do
  use ExUnit.Case
  import Checkov

  describe "new/1" do
    data_test "validates #{field} against bad input" do
      input = put_in(%{}, [field], value)
      assert {:error, [%{input: value, path: [field]} | _]} = Profile.Update.new(input)

      where([
        [:field, :value],
        [:version, "1"],
        [:dataset_id, nil],
        [:dataset_id, 2001],
        [:subset_id, nil],
        [:subset_id, ""],
        [:stats, []]
      ])
    end

    test "updated is automatically set" do
      update =
        Profile.Update.new!(
          dataset_id: "ds1",
          subset_id: "sb1"
        )

      assert update.updated != nil
    end
  end
end

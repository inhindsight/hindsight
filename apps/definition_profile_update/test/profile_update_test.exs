defmodule Profile.UpdateTest do
  use ExUnit.Case

  describe "new/1" do
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

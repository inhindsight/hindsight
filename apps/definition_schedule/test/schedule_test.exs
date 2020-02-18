defmodule ScheduleTest do
  use Checkov
  doctest Schedule

  describe "new/1" do
    data_test "validates #{field} against bad input" do
      input = put_in(%{}, [field], value)
      assert {:error, [%{input: value, path: [field]} | _]} = Schedule.new(input)

      where [
        [:field, :value],
        [:version, "1"],
        [:id, ""],
        [:dataset_id, ""],
        [:dataset_id, nil],
        [:subset_id, ""],
        [:subset_id, nil],
        [:cron, ""],
        [:cron, nil],
        [:compaction_cron, ""],
        [:compaction_cron, nil],
        [:extract, %{}],
        [:transform, nil],
        [:load, nil]
      ]
    end
  end
end

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
        [:dataset_id, nil],
        [:cron, ""],
        [:extract, %{}],
        [:transform, nil],
        [:load, nil]
      ]
    end
  end
end

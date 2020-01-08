defmodule Writer.DLQ.DeadLetterTest do
  use ExUnit.Case
  import Checkov

  data_test "validates" do
    assert {:error, [%{input: value, path: [field]} | _]} =
             put_in(%{}, [field], value)
             |> Writer.DLQ.DeadLetter.new()

    where([
      [:field, :value],
      [:version, "1"],
      [:dataset_id, 1],
      [:dataset_id, ""],
      [:original_message, nil],
      [:app_name, 1],
      [:app_name, ""],
      [:stacktrace, 1],
      [:reason, nil],
      [:timestamp, 1]
    ])
  end
end

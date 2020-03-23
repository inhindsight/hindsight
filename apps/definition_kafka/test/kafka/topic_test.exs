defmodule Kafka.TopicTest do
  use ExUnit.Case
  import Checkov

  describe "new/1" do
    data_test "validates #{field} with value #{value} against bad input" do
      input = put_in(%{}, [field], value)
      {:error, errors} = Kafka.Topic.new(input)

      assert Enum.any?(errors, fn err -> err.input == value && err.path == [field] end)

      where [
        [:field, :value],
        [:version, "1"],
        [:topic, nil],
        [:topic, 1],
        [:partitions, -1],
        [:partitions, "1"],
        [:partitioner, "jerks"],
        [:key_path, nil]
      ]
    end
  end
end

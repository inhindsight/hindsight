defmodule Kafka.TopicTest do
  use ExUnit.Case

  test "can be serialized and deserialized by brook" do
    source =
      Kafka.Topic.new!(
        name: "topic",
        endpoints: [localhost: 9092]
      )

    {:ok, serialized} = Brook.Serializer.serialize(source)
    {:ok, deserialized} = Brook.Deserializer.deserialize(serialized)

    assert source == deserialized
  end
end

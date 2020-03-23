defmodule Kafka.Topic.DestinationTest do
  use ExUnit.Case
  use Divo
  import AssertAsync

  @endpoints [localhost: 9092]

  describe "delete/1" do
    test "topic can be deleted" do
      {:ok, topic} = Kafka.Topic.new(endpoints: @endpoints, topic: "delete-me")

      Elsa.create_topic(@endpoints, topic.topic)

      assert_async debug: true do
        assert Elsa.topic?(@endpoints, topic.topic)
      end

      assert :ok = Destination.delete(topic)

      assert_async debug: true do
        refute Elsa.topic?(@endpoints, topic.topic)
      end
    end

    test "returns error tuple if topic cannot be deleted" do
      topic = Kafka.Topic.new!(endpoints: @endpoints, topic: "never-existed")
      assert {:error, {:unknown_topic_or_partition, _}} = Destination.delete(topic)
    end
  end
end

defmodule Writer.Kafka.TopicTest do
  use ExUnit.Case
  use Divo
  import AssertAsync

  @moduletag integration: true, divo: true

  alias Writer.Kafka.Topic

  @server [localhost: 9092]

  test "topic writer will create topic and produce messages" do
    {:ok, writer} = start_supervised({Topic, endpoints: @server, topic: "topic-435"})

    {:ok, topics} = Elsa.list_topics(@server)
    assert {"topic-435", 1} in topics

    :ok = Topic.write(writer, ["message1"])

    assert_async debug: true do
      {:ok, _count, messages} = Elsa.fetch(@server, "topic-435")
      assert Enum.any?(messages, &match?(%{value: "message1"}, &1))
    end
  end

  test "topic will create topic with given number of partitions" do
    {:ok, _writer} =
      start_supervised({Topic, endpoints: @server, topic: "topic-721", partitions: 3})

    {:ok, topics} = Elsa.list_topics(@server)
    assert {"topic-721", 3} in topics
  end
end

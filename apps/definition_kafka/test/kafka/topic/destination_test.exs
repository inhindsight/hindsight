defmodule Kafka.Topic.DestinationTest do
  use ExUnit.Case
  use Divo
  import AssertAsync

  @endpoints [localhost: 9092]

  setup do
    Process.flag(:trap_exit, true)
    :ok
  end

  describe "start_link/2" do
    test "returns topic struct with pid" do
      topic = Kafka.Topic.new!(endpoints: @endpoints, name: "noop")
      {:ok, topic} = Destination.start_link(topic, [])

      assert is_pid(topic.pid)

      assert_down(topic.pid)
    end

    test "creates topic in Kafka" do
      topic = Kafka.Topic.new!(endpoints: @endpoints, name: "create-me")
      {:ok, topic} = Destination.start_link(topic, [])

      assert_async debug: true do
        assert Elsa.topic?(@endpoints, topic.name)
      end

      assert_down(topic.pid)
    end

    test "creates topic with configurable number of partitions" do
      topic = Kafka.Topic.new!(endpoints: @endpoints, name: "partitioned", partitions: 3)
      {:ok, topic} = Destination.start_link(topic, [])

      assert_async debug: true do
        assert Elsa.topic?(@endpoints, topic.name)
        assert Elsa.Util.partition_count(@endpoints, topic.name) == 3
      end

      assert_down(topic.pid)
    end
  end

  describe "write/3" do
    test "produces messages to Kafka" do
      topic = Kafka.Topic.new!(endpoints: @endpoints, name: "write-me")
      {:ok, topic} = Destination.start_link(topic, [])

      assert :ok = Destination.write(topic, ["one", "two"])

      assert_async debug: true do
        assert Elsa.topic?(@endpoints, topic.name)
        {:ok, _count, messages} = Elsa.fetch(@endpoints, topic.name)
        assert [{"", "one"}, {"", "two"}] == Enum.map(messages, &{&1.key, &1.value})
      end

      assert_down(topic.pid)
    end
  end

  describe "delete/1" do
    test "deletes topic from Kafka" do
      {:ok, topic} = Kafka.Topic.new(endpoints: @endpoints, name: "delete-me")

      Elsa.create_topic(@endpoints, topic.name)

      assert_async debug: true do
        assert Elsa.topic?(@endpoints, topic.name)
      end

      assert :ok = Destination.delete(topic)

      assert_async debug: true do
        refute Elsa.topic?(@endpoints, topic.name)
      end
    end

    test "returns error tuple if topic cannot be deleted" do
      topic = Kafka.Topic.new!(endpoints: @endpoints, name: "never-existed")
      assert {:error, {:unknown_topic_or_partition, _}} = Destination.delete(topic)
    end
  end

  defp assert_down(pid) do
    ref = Process.monitor(pid)
    Process.exit(pid, :kill)
    assert_receive {:DOWN, ^ref, _, _, _}
  end
end

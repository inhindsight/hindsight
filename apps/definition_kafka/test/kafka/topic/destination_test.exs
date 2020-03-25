defmodule Kafka.Topic.DestinationTest do
  use ExUnit.Case
  use Divo

  require Temp.Env
  import AssertAsync
  import Mox

  @endpoints [localhost: 9092]
  @moduletag integration: true, divo: true

  Temp.Env.modify([
    %{
      app: :definition_kafka,
      key: Kafka.Topic.Destination,
      set: [dlq: DlqMock]
    }
  ])

  setup :set_mox_global
  setup :verify_on_exit!

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

  describe "write/2" do
    test "produces messages to Kafka" do
      topic = Kafka.Topic.new!(endpoints: @endpoints, name: "write-me")
      {:ok, topic} = Destination.start_link(topic, [])

      assert :ok = Destination.write(topic, ["one", "two"])

      assert_async debug: true do
        assert Elsa.topic?(@endpoints, topic.name)
        {:ok, _, messages} = Elsa.fetch(@endpoints, topic.name)
        assert ["one", "two"] == Enum.map(messages, & &1.value)
      end

      assert_down(topic.pid)
    end

    test "encodes maps to JSON before producing to Kafka" do
      topic = Kafka.Topic.new!(endpoints: @endpoints, name: "write-maps")
      {:ok, topic} = Destination.start_link(topic, [])

      assert :ok = Destination.write(topic, [%{one: 1}, %{two: 2}])

      assert_async debug: true do
        assert Elsa.topic?(@endpoints, topic.name)
        {:ok, _, messages} = Elsa.fetch(@endpoints, topic.name)

        assert [{"", ~s|{"one":1}|}, {"", ~s|{"two":2}|}] ==
                 Enum.map(messages, &{&1.key, &1.value})
      end

      assert_down(topic.pid)
    end

    test "keys message off topic's key_path field" do
      topic = Kafka.Topic.new!(endpoints: @endpoints, name: "key-me", key_path: ["a", "b"])
      {:ok, topic} = Destination.start_link(topic, [])

      input = [%{"a" => %{"b" => "1"}}, %{"a" => %{"b" => "2"}}]
      assert :ok = Destination.write(topic, input)

      assert_async debug: true do
        assert Elsa.topic?(@endpoints, topic.name)
        {:ok, _, messages} = Elsa.fetch(@endpoints, topic.name)

        # TODO keys can only be binary?
        assert [{"1", ~s|{"a":{"b":"1"}}|}, {"2", ~s|{"a":{"b":"2"}}|}] =
                 Enum.map(messages, &{&1.key, &1.value})
      end

      assert_down(topic.pid)
    end

    test "writes errors to DLQ" do
      expect(DlqMock, :write, fn _ -> :ok end)

      opts = [app_name: "foo", dataset_id: "bar", subset_id: "baz"]
      topic = Kafka.Topic.new!(endpoints: @endpoints, name: "write-errors")
      {:ok, topic} = Destination.start_link(topic, opts)

      assert :ok = Destination.write(topic, [%{one: 1}, ~r/no/, %{two: 2}])

      assert_async debug: true do
        assert Elsa.topic?(@endpoints, topic.name)
        {:ok, _, messages} = Elsa.fetch(@endpoints, topic.name)
        assert [~s|{"one":1}|, ~s|{"two":2}|] == Enum.map(messages, & &1.value)
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

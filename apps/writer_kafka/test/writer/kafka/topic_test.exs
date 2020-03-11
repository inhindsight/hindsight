defmodule Writer.Kafka.TopicTest do
  use ExUnit.Case
  use Divo
  use Placebo
  import AssertAsync

  @moduletag integration: true, divo: true

  alias Writer.Kafka.Topic

  @server [localhost: 9092]

  setup do
    test = self()

    handler_function = fn event_name, event_measurements, event_metadata, handler_config ->
      send(
        test,
        {:telemetry_event, event_name, event_measurements, event_metadata, handler_config}
      )
    end

    :telemetry.attach(__MODULE__, [:writer, :kafka, :produce], handler_function, %{})

    on_exit(fn -> :telemetry.detach(__MODULE__) end)

    :ok
  end

  test "topic writer will create topic and produce messages" do
    {:ok, writer} =
      start_supervised(
        {Topic,
         endpoints: @server,
         topic: "topic-435",
         metric_metadata: %{app: "testing", dataset_id: "ds1", subset_id: "sb1"}}
      )

    :ok = Topic.write(writer, ["message1", {"key2", "message2"}])

    assert_async debug: true do
      assert Elsa.topic?(@server, "topic-435")
      {:ok, _count, messages} = Elsa.fetch(@server, "topic-435")
      assert [{"", "message1"}, {"key2", "message2"}] == Enum.map(messages, &{&1.key, &1.value})
    end

    expected_metadata = %{app: "testing", dataset_id: "ds1", subset_id: "sb1", topic: "topic-435"}

    assert_receive {:telemetry_event, [:writer, :kafka, :produce], %{count: 2},
                    ^expected_metadata, %{}}
  end

  test "topic writer will report correct number of messages sent, in case of partial failure" do
    allow Elsa.produce(any(), "topic-435", any(), any()),
      return: {:error, "failure", ["message3"]}

    {:ok, writer} = start_supervised({Topic, endpoints: @server, topic: "topic-435"})

    assert {:error, "failure", ["message3"]} =
             Topic.write(writer, ["message1", "message2", "message3"])

    assert_receive {:telemetry_event, [:writer, :kafka, :produce], %{count: 2}, _, _}, 5_000
  end

  test "topic writer will allow custom partition to be defined" do
    expect Elsa.produce(any(), "topic-123", any(), partitioner: :md5), return: :ok

    config = %{
      "kafka" => %{
        "partitioner" => "md5"
      }
    }

    {:ok, writer} =
      start_supervised({Topic, endpoints: @server, topic: "topic-123", config: config})

    assert :ok == Topic.write(writer, ["message1"])
  end

  test "will create topic with specified number of partitions" do
    config = %{
      "kafka" => %{
        "partitions" => 4,
        "partitioner" => "md5"
      }
    }

    {:ok, _writer} =
      start_supervised({Topic, endpoints: @server, topic: "topic-4p", config: config})

    assert_async debug: true do
      assert Elsa.topic?(@server, "topic-4p")
      assert 4 == Elsa.Util.partition_count(@server, "topic-4p")
    end
  end
end

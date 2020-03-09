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

    :ok = Topic.write(writer, ["message1"])

    assert_async debug: true do
      {:ok, _count, messages} = Elsa.fetch(@server, "topic-435")
      assert Enum.any?(messages, &match?(%{value: "message1"}, &1))
    end

    expected_metadata = %{app: "testing", dataset_id: "ds1", subset_id: "sb1", topic: "topic-435"}

    assert_receive {:telemetry_event, [:writer, :kafka, :produce], %{count: 1},
                    ^expected_metadata, %{}}
  end

  test "topic writer will report correct number of messages sent, in case of partial failure" do
    allow Elsa.produce(any(), "topic-435", any(), any()), return: {:error, "failure", ["message3"]}

    {:ok, writer} = start_supervised({Topic, endpoints: @server, topic: "topic-435"})

    assert {:error, "failure", ["message3"]} =
             Topic.write(writer, ["message1", "message2", "message3"])

    assert_receive {:telemetry_event, [:writer, :kafka, :produce], %{count: 2}, _, _}, 5_000
  end

  test "topic writer will allow custom partition to be defined" do
    expect Elsa.produce(any(), "topic-123", any(), [partitioner: :md5]), return: :ok

    {:ok, writer} = start_supervised({Topic, endpoints: @server, topic: "topic-123", partitioner: :md5})

    assert :ok == Topic.write(writer, ["message1"])
  end

  test "write can overwrite partition" do
    expect Elsa.produce(any(), "topic-123", any(), [partition: 0]), return: :ok

    {:ok, writer} = start_supervised({Topic, endpoints: @server, topic: "topic-123", partitioner: :md5})

    assert :ok == Topic.write(writer, ["message"], partition: 0)
  end

  test "write can overwrite partitioner" do
    expect Elsa.produce(any(), "topic-123", any(), [partitioner: :random]), return: :ok

    {:ok, writer} = start_supervised({Topic, endpoints: @server, topic: "topic-123", partitioner: :md5})

    assert :ok == Topic.write(writer, ["message"], partitioner: :random)
  end
end

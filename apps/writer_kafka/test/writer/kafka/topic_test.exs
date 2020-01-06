defmodule Writer.Kafka.TopicTest do
  use ExUnit.Case
  use Divo
  import AssertAsync

  @moduletag integration: true, divo: true

  alias Writer.Kafka.Topic

  @server [localhost: 9092]

  test "topic writer will create topic and produce messages" do
    {:ok, writer} =
      Topic.start_link(
        endpoints: @server,
        topic: "topic-435"
      )

    :ok = Topic.write(writer, ["message1"])

    assert_async debug: true do
      {:ok, _count, messages} = Elsa.fetch(@server, "topic-435")
      assert Enum.any?(messages, &match?(%{value: "message1"}, &1))
    end
  end
end

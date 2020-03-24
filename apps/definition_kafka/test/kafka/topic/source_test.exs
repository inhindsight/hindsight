defmodule Kafka.Topic.SourceTest do
  use ExUnit.Case
  use Divo
  import AssertAsync

  @endpoints [localhost: 9092]
  @topic "source-test"

  defmodule Handler do
    use Source.Handler

    def handle_batch(messages) do
      test = Agent.get(Kafka.Topic.SourceTest, fn s -> s end)
      send(test, {:handle_batch, messages})
      :ok
    end
  end

  setup do
    test = self()

    start_supervised(%{
      id: :agent_0,
      start: {Agent, :start_link, [fn -> test end, [name: __MODULE__]]}
    })

    source = %Kafka.Topic{
      endpoints: @endpoints,
      topic: @topic
    }

    dictionary =
      Dictionary.from_list([
        Dictionary.Type.String.new!(name: "name")
      ])

    [source: source, dictionary: dictionary]
  end

  test "should create topic if necessary with proper number of partitions", %{
    dictionary: dictionary
  } do
    source = %Kafka.Topic{
      endpoints: @endpoints,
      topic: "create-test",
      partitions: 2
    }

    {:ok, source} =
      Source.start_link(source,
        dictionary: dictionary,
        handler: Handler,
        app_name: "testing",
        dataset_id: "ds1",
        subset_id: "sb1"
      )

    assert_async do
      assert Elsa.topic?(@endpoints, "create-test")
    end

    {:ok, topics} = Elsa.list_topics(@endpoints)
    assert Enum.any?(topics, fn x -> x == {"create-test", 2} end)

    assert_down(source)
  end

  test "will decode messages and pass them to handler", %{
    source: source,
    dictionary: dictionary
  } do
    {:ok, source} =
      Source.start_link(source,
        dictionary: dictionary,
        handler: Handler,
        app_name: "testing",
        dataset_id: "ds1",
        subset_id: "sb1"
      )

    assert_async do
      assert Elsa.topic?(@endpoints, @topic)
    end

    messages = [
      %{"name" => "joe", "age" => 2},
      %{"name" => "bob", "age" => 56}
    ]

    assert :ok = Elsa.produce(@endpoints, @topic, Enum.map(messages, &Jason.encode!/1))

    assert_receive {:handle_batch, ^messages}, 5_000

    assert_down(source)
  end

  test "stop/1 will stop the process", %{source: source, dictionary: dictionary} do
    {:ok, source} =
      Source.start_link(source,
        dictionary: dictionary,
        handler: Handler,
        app_name: "testing",
        dataset_id: "ds1",
        subset_id: "sb1"
      )

    Source.stop(source)

    assert_async sleep: 500 do
      refute Process.alive?(source.pid)
    end
  end

  test "delete/1 should remote topic from kafak" do
    source = %Kafka.Topic{
      topic: "topic-to-delete",
      endpoints: @endpoints
    }

    Elsa.create_topic(@endpoints, "topic-to-delete")

    assert_async do
      assert Elsa.topic?(@endpoints, "topic-to-delete")
    end

    Source.delete(source)

    assert_async do
      refute Elsa.topic?(@endpoints, "topic-to-delete")
    end
  end

  defp assert_down(t) do
    ref = Process.monitor(t.pid)
    Source.stop(t)
    assert_receive {:DOWN, ^ref, _, _, _}, 5_000
  end
end

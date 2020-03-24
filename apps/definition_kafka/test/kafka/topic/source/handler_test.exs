defmodule Kafka.Topic.Source.HandlerTest do
  use ExUnit.Case
  import Mox
  require Temp.Env

  Temp.Env.modify([
    %{
      app: :definition_kafka,
      key: Kafka.Topic.Source.Handler,
      set: [
        dlq: DlqMock
      ]
    }
  ])

  defmodule SourceHandler do
    use Source.Handler

    def handle_message(%{"raise" => reason}) do
      raise reason
    end

    def handle_message(%{"error" => reason}) do
      {:error, reason}
    end

    def handle_message(message) do
      test = Agent.get(Kafka.Topic.Source.HandlerTest, fn s -> s end)
      send(test, {:handle_message, message})
      {:ok, message}
    end

    def handle_batch(batch) do
      test = Agent.get(Kafka.Topic.Source.HandlerTest, fn s -> s end)
      send(test, {:handle_batch, batch})
      :ok
    end
  end

  setup do
    test = self()

    DlqMock
    |> stub(:write, fn messages ->
      send(test, {:dlq, messages})
      :ok
    end)

    start_supervised(%{
      id: :agent_0,
      start: {Agent, :start_link, [fn -> test end, [name: __MODULE__]]}
    })

    state = %{
      source_handler: SourceHandler,
      app_name: "testing",
      dataset_id: "ds1",
      subset_id: "sb1"
    }

    [state: state]
  end

  test "messages are decoded and passed to handle_message and handle_batch", %{state: state} do
    messages = [
      %{"name" => "joe", "age" => 1},
      %{"name" => "bob", "age" => 2}
    ]

    assert {:ack, _} = Kafka.Topic.Source.Handler.handle_messages(em(messages), state)

    Enum.each(messages, fn message ->
      assert_received {:handle_message, ^message}
    end)
    assert_received {:handle_batch, ^messages}
  end

  test "will send  error messages to dlq", %{state: state} do
    message1 = %{"name" => "joe"}
    message2 = %{value: "{\"one:}"}
    message3 = %{"name" => "bob"}
    message4 = %{"error" => "returned error"}
    message5 = %{"name" => "pete"}
    message6 = %{"raise" => "raised error"}

    messages = [
      em(message1),
      message2,
      em(message3),
      em(message4),
      em(message5),
      em(message6)
    ]

    assert {:ack, _} = Kafka.Topic.Source.Handler.handle_messages(messages, state)

    assert_received {:handle_message, ^message1}
    assert_received {:handle_message, ^message3}
    assert_received {:handle_message, ^message5}
    assert_received {:handle_batch, [^message1, ^message3, ^message5]}

    assert_received {:dlq, [dead_letter2, dead_letter4, dead_letter6]}

    {:error, reason} = Jason.decode(message2.value)

    assert dead_letter2.app_name == state.app_name
    assert dead_letter2.dataset_id == state.dataset_id
    assert dead_letter2.subset_id == state.subset_id
    assert dead_letter2.reason == Exception.format(:error, reason)
    assert dead_letter2.original_message == message2

    assert dead_letter4.app_name == state.app_name
    assert dead_letter4.dataset_id == state.dataset_id
    assert dead_letter4.subset_id == state.subset_id
    assert dead_letter4.reason == ~s|** (ErlangError) Erlang error: "returned error"|
    assert dead_letter4.original_message == %{value: Jason.encode!(message4)}

    assert dead_letter6.app_name == state.app_name
    assert dead_letter6.dataset_id == state.dataset_id
    assert dead_letter6.subset_id == state.subset_id
    assert dead_letter6.reason == ~s|** (RuntimeError) raised error|
    assert dead_letter6.original_message == %{value: Jason.encode!(message6)}
  end

  defp em(list) when is_list(list) do
    Enum.map(list, &em/1)
  end

  defp em(map) do
    %{value: Jason.encode!(map)}
  end
end

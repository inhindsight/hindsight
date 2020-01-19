defmodule Kafka.SubscribeTest do
  use ExUnit.Case
  use Divo

  alias Extract.Steps.Context

  test "Kafka.Subscribe" do
    step = %Kafka.Subscribe{endpoints: [localhost: 9092], topic: "topic-a"}

    {:ok, context} = Extract.Step.execute(step, Context.new())

    Task.async(fn ->
      Process.sleep(2_000)

      Enum.each(1..100, fn i ->
        Elsa.produce([localhost: 9092], "topic-a", ["message-#{i}"], partition: 0)
      end)
    end)

    messages =
      context
      |> Context.get_stream()
      |> Stream.take(100)
      |> Stream.map(&Map.get(&1, :value))
      |> Enum.to_list()

    expected = Enum.map(1..100, fn i -> "message-#{i}" end)

    assert expected == messages
  end
end

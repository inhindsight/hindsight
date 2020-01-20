defmodule Kafka.SubscribeTest do
  use ExUnit.Case
  use Divo
  import AssertAsync
  require Logger

  @moduletag integration: true, divo: true

  alias Extract.Steps.Context

  setup do
    Process.flag(:trap_exit, true)

    :ok
  end

  test "Kafka.Subscribe" do
    step = %Kafka.Subscribe{endpoints: [localhost: 9092], topic: "topic-a"}

    {:ok, context} = Extract.Step.execute(step, Context.new())

    messages = Enum.map(1..100, fn i -> "message-#{i}" end)

    Task.async(fn ->
      Process.sleep(2_000)
      Elsa.produce([localhost: 9092], "topic-a", messages, partition: 0)
    end)

    actuals =
      context
      |> Context.get_stream()
      |> Stream.take(100)
      |> Stream.map(&Map.get(&1, :value))
      |> Stream.chunk_every(10)
      |> Stream.each(fn chunk ->
        Context.run_after_functions(context, chunk)
      end)
      |> Enum.to_list()
      |> List.flatten()

    assert actuals == messages

    assert_async do
      assert {:links, []} == Process.info(self(), :links)
    end
  end
end

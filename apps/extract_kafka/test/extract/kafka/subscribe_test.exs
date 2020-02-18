defmodule Extract.Kafka.SubscribeTest do
  use ExUnit.Case
  use Divo
  import Checkov
  import AssertAsync
  require Logger

  @moduletag integration: true, divo: true

  alias Extract.Context

  setup do
    Process.flag(:trap_exit, true)

    :ok
  end

  describe "new/1" do
    data_test "validates #{inspect(field)} against bad input" do
      assert {:error, [%{input: value, path: [field]} | _]} =
               put_in(%{}, [field], value)
               |> Extract.Kafka.Subscribe.new()

      where([
        [:field, :value],
        [:version, "1"],
        [:endpoints, "a"],
        [:endpoints, nil],
        [:topic, ""],
        [:topic, nil]
      ])
    end
  end

  test "can be decoded back into struct" do
    struct = Extract.Kafka.Subscribe.new!(endpoints: [localhost: 8080], topic: "topic")
    json = Jason.encode!(struct)

    assert {:ok, struct} == Jason.decode!(json) |> Extract.Kafka.Subscribe.new()
  end

  test "brook serializer can serialize and deserialize" do
    struct = Extract.Kafka.Subscribe.new!(endpoints: [localhost: 8080], topic: "topic")

    assert {:ok, struct} =
             Brook.Serializer.serialize(struct) |> elem(1) |> Brook.Deserializer.deserialize()
  end

  describe "Extract.Step" do
    test "Extract.Kafka.Subscribe" do
      step = %Extract.Kafka.Subscribe{endpoints: [localhost: 9092], topic: "topic-a"}

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
        |> Stream.chunk_every(10)
        |> Stream.each(fn chunk ->
          Context.run_after_functions(context, chunk)
        end)
        |> Enum.to_list()
        |> List.flatten()

      assert actuals ==
               messages
               |> Enum.reduce({0, []}, fn data, {i, buffer} ->
                 message =
                   Extract.Message.new(
                     data: data,
                     meta: %{
                       "kafka" => %{
                         "offset" => i,
                         "generation_id" => 1,
                         "partition" => 0,
                         "topic" => "topic-a"
                       }
                     }
                   )

                 {i + 1, buffer ++ [message]}
               end)
               |> elem(1)

      assert_async do
        assert {:links, []} == Process.info(self(), :links)
      end
    end
  end
end

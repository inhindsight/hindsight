defmodule Gather.PerformanceTest do
  use ExUnit.Case
  use Divo
  import AssertAsync

  @moduletag performance: true, divo: true
  @kafka [localhost: 9092]
  @partitions 1

  @data_size "medium"
  @partitioner if @partitions == 1, do: :default, else: :random

  setup do
    Elsa.create_topic(@kafka, "gather-input", partitions: @partitions)

    start_supervised!(
      {Elsa.Supervisor, endpoints: @kafka, connection: :kafka, producer: [topic: "gather-input"]}
    )

    File.stream!("../../apps/platform_runner/data/#{@data_size}")
    |> Stream.chunk_every(100)
    |> Enum.each(fn chunk ->
      Elsa.produce(:kafka, "gather-input", chunk, partitioner: @partitioner)
    end)

    :ok
  end

  @tag timeout: :infinity
  test "gather performance test" do
    Benchee.run(
      %{
        "run" => fn ->
          gather()
        end
      },
      memory_time: 2,
      time: 60
    )
  end

  defp gather() do
    number = :rand.uniform(1_000_000)
    IO.puts("Number: #{number}")

    dictionary =
      File.read!("../../apps/platform_runner/data/#{@data_size}-dictionary")
      |> Dictionary.decode()
      |> elem(1)
      |> Dictionary.from_list()

    extract =
      Extract.new!(
        dataset_id: "ds#{number}",
        subset_id: "sb1",
        source:
          Kafka.Topic.new!(
            endpoints: @kafka,
            name: "gather-input",
            group: "gather-input-#{number}"
          ),
        destination:
          Kafka.Topic.new!(
            endpoints: @kafka,
            name: "gather-output-#{number}",
            partitions: 1,
            partitioner: :default
          ),
        dictionary: dictionary,
        decoder: Decoder.JsonLines.new!([])
      )

    Gather.Application.instance()
    |> Events.send_extract_start("testing", extract)

    transform =
      Transform.new!(
        id: "id-1",
        dataset_id: "ds#{number}",
        subset_id: "sb1",
        dictionary: dictionary,
        steps: []
      )

    Gather.Application.instance()
    |> Events.send_transform_define("performance", transform)

    assert_async debug: true, sleep: 500, max_tries: 120 do
      assert Elsa.topic?(@kafka, "gather-output-#{number}")
      assert 100_000 == get_count_of_messages("gather-output-#{number}")
    end

    IO.puts("it worked - #{number}")
  end

  defp get_count_of_messages(topic) do
    partition_count = Elsa.Util.partition_count(@kafka, topic)
    0..(partition_count - 1)
    |> Enum.reduce(0, fn partition, sum ->
      {:ok, offset} = :brod.resolve_offset(@kafka, topic, partition)
      sum + offset
    end)
  end
end

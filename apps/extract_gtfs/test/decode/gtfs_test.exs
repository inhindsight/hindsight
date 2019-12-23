defmodule Decode.GtfsTest do
  use ExUnit.Case

  alias Extract.Steps.Context

  test "decodes gtfs into stream" do
    message = generate_feed(10)
    gtfs_binary = TransitRealtime.FeedMessage.encode(message)

    context = Context.new() |> Context.set_stream(gtfs_binary)

    {:ok, context} = Extract.Step.execute(%Decode.Gtfs{}, context)
    assert message.entity == Enum.to_list(context.stream)
  end

  test "returns errors tuple when stream is not available" do
    {:error, reason} = Extract.Step.execute(%Decode.Gtfs{}, Context.new())

    expected =
      Extract.InvalidContextError.exception(message: "Invalid stream", step: %Decode.Gtfs{})

    assert reason == expected
  end

  test "returns erro tuple when stream is not valid gtfs" do
    context = Context.new() |> Context.set_stream("hello joe")
    {:error, reason} = Extract.Step.execute(%Decode.Gtfs{}, context)

    error =
      try do
        TransitRealtime.FeedMessage.decode(context.stream)
      rescue
        e -> Exception.message(e)
      end

    expected = Decode.Gtfs.InvalidGtfsError.exception(bytes: context.stream, message: error)
    assert reason == expected
  end

  defp generate_feed(number_of_entities) do
    header = TransitRealtime.FeedHeader.new(gtfs_realtime_version: "1.0")

    entities =
      0..number_of_entities
      |> Enum.map(&TransitRealtime.FeedEntity.new(id: to_string(&1)))

    TransitRealtime.FeedMessage.new(entity: entities, header: header)
  end
end

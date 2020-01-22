defmodule Decode.GtfsTest do
  use ExUnit.Case

  alias Extract.Steps.Context

  test "decodes gtfs into stream" do
    source = fn opts ->
      lines_or_bytes = Context.lines_or_bytes(opts)
      File.stream!("VehiclePositions.pb", [], lines_or_bytes)
    end

    context = Context.new() |> Context.set_source(source)

    expected = File.read!("VehiclePositions.pb") |> TransitRealtime.FeedMessage.decode()

    {:ok, context} = Extract.Step.execute(%Extract.Decode.Gtfs{}, context)
    assert expected.entity == Context.get_stream(context)
  end
end

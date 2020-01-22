defmodule Extract.Decode.GtfsTest do
  use ExUnit.Case

  alias Extract.Steps.Context

  test "can be decoded back into struct" do
    struct = Extract.Decode.Gtfs.new!([])
    json = Jason.encode!(struct)

    assert {:ok, struct} == Jason.decode!(json) |> Extract.Decode.Gtfs.new()
  end

  test "brook serializer can serialize and deserialize" do
    struct = Extract.Decode.Gtfs.new!([])

    assert {:ok, struct} =
             Brook.Serializer.serialize(struct) |> elem(1) |> Brook.Deserializer.deserialize()
  end

  describe "Extract.Step" do
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
end

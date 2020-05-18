defmodule Decoder.GtfsTest do
  use ExUnit.Case

  test "can be decoded back into struct" do
    struct = Decoder.Gtfs.new!([])
    json = Jason.encode!(struct)

    assert {:ok, struct} == Jason.decode!(json) |> Decoder.Gtfs.new()
  end

  test "brook serializer can serialize and deserialize" do
    struct = Decoder.Gtfs.new!([])

    assert {:ok, struct} =
             Brook.Serializer.serialize(struct) |> elem(1) |> Brook.Deserializer.deserialize()
  end

  describe "Decoder" do
    test "decodes gtfs into stream" do
      decoder = Decoder.Gtfs.new!([])
      input = File.read!("VehiclePositions.pb")

      output = Decoder.decode(decoder, input)

      expected =
        File.read!("VehiclePositions.pb")
        |> TransitRealtime.FeedMessage.decode()
        |> Map.get(:entity)
        |> Enum.map(&Decoder.Gtfs.decode_struct/1)

      assert output == expected
    end
  end
end

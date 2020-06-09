defmodule Decoder.GtfsTest do
  use ExUnit.Case

  test "can be serialized" do
    struct = Decoder.Gtfs.new!([])

    serialized = JsonSerde.serialize!(struct)

    assert JsonSerde.deserialize!(serialized) == struct
  end

  describe "Decoder" do
    test "decodes gtfs into batch of messages" do
      decoder = Decoder.Gtfs.new!([])
      input = File.read!("VehiclePositions.pb")

      output = Decoder.decode(decoder, input)

      expected =
        input
        |> TransitRealtime.FeedMessage.decode()
        |> Map.get(:entity)
        |> Enum.map(&Decoder.Gtfs.decode_struct/1)

      assert output == expected
    end
  end
end

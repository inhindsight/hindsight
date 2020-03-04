defmodule Extract.Decode.GtfsTest do
  use ExUnit.Case

  alias Extract.Context

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
        |> Stream.transform(0, fn data, acc ->
          {[Extract.Message.new(data: data, meta: %{"id" => acc})], acc + 1}
        end)
        |> Stream.chunk_every(10)
      end

      expected_id =
        source.(read: :bytes)
        |> Enum.to_list()
        |> List.flatten()
        |> List.last()
        |> get_in([Access.key(:meta), "id"])

      context = Context.new() |> Context.set_source(source)

      expected =
        File.read!("VehiclePositions.pb")
        |> TransitRealtime.FeedMessage.decode()
        |> Map.get(:entity)
        |> Enum.map(&decode_struct/1)
        |> Enum.map(fn entity ->
          Extract.Message.new(data: entity, meta: %{"id" => expected_id})
        end)

      {:ok, context} = Extract.Step.execute(%Extract.Decode.Gtfs{}, context)

      assert Enum.chunk_every(expected, 2) ==
               Context.get_stream(context, chunk_size: 2) |> Enum.to_list()
    end
  end

  defp decode_struct(%_struct{} = entity) do
    entity
    |> Map.from_struct()
    |> Map.new(fn {k, v} -> {Atom.to_string(k), decode_struct(v)} end)
  end

  defp decode_struct(element), do: element
end

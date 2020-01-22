defmodule Extract.Decode.JsonLinesTest do
  use ExUnit.Case

  alias Extract.Steps.Context

  test "can be decoded back into struct" do
    struct = Extract.Decode.JsonLines.new!([])
    json = Jason.encode!(struct)

    assert {:ok, struct} == Jason.decode!(json) |> Extract.Decode.JsonLines.new()
  end

  test "brook serializer can serialize and deserialize" do
    struct = Extract.Decode.JsonLines.new!([])

    assert {:ok, struct} =
             Brook.Serializer.serialize(struct) |> elem(1) |> Brook.Deserializer.deserialize()
  end

  describe "Extract.Step" do
    test "decodes json lines file as a stream" do
      source = fn _ ->
        [
          json(%{"name" => "john", "age" => 21}),
          json(%{"name" => "Fred", "age" => 34}),
          json(%{"name" => "george", "age" => 36})
        ]
      end

      context = Context.new() |> Context.set_source(source)
      {:ok, context} = Extract.Step.execute(%Extract.Decode.JsonLines{}, context)

      assert Context.get_stream(context) |> Enum.to_list() == [
               %{"name" => "john", "age" => 21},
               %{"name" => "Fred", "age" => 34},
               %{"name" => "george", "age" => 36}
             ]
    end
  end

  defp json(map), do: Jason.encode!(map)
end

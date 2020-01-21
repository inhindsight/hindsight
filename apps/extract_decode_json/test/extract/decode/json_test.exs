defmodule Extract.Decode.JsonTest do
  use ExUnit.Case

  alias Extract.Steps.Context

  test "can be decoded back into struct" do
    struct = Extract.Decode.Json.new!([])
    json = Jason.encode!(struct)

    assert {:ok, struct} == Jason.decode!(json) |> Extract.Decode.Json.new()
  end

  test "brook serializer can serialize and deserialize" do
    struct = Extract.Decode.Json.new!([])

    assert {:ok, struct} =
             Brook.Serializer.serialize(struct) |> elem(1) |> Brook.Deserializer.deserialize()
  end

  describe "Extract.Step" do
    test "decodes context stream to json" do
      source = fn _ ->
        [
          ~s([),
          ~s({\"name\": \"Kyle\", \"age\": 2},{\"name\": \"Joe\"),
          ~s(, \"age\": 21},{\"name\": \"Bobby\",\"age\": 62}),
          ~s(])
        ]
      end

      context = Context.new() |> Context.set_source(source)
      {:ok, context} = Extract.Step.execute(%Extract.Decode.Json{}, context)

      expected = [
        %{"name" => "Kyle", "age" => 2},
        %{"name" => "Joe", "age" => 21},
        %{"name" => "Bobby", "age" => 62}
      ]

      assert Context.get_stream(context) == expected
    end

    test "decodes a non-list stream to json" do
      source = fn _ ->
        [
          ~s({"name": "Jay",),
          ~s("age": 42})
        ]
      end

      context = Context.new() |> Context.set_source(source)
      {:ok, context} = Extract.Step.execute(%Extract.Decode.Json{}, context)

      expected = [%{"name" => "Jay", "age" => 42}]
      assert Context.get_stream(context) == expected
    end
  end
end

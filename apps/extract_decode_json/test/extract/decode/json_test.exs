defmodule Extract.Decode.JsonTest do
  use ExUnit.Case

  alias Extract.Context

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
          [~s([), ~s({\"name\": \"Kyle\", \"age\": 2},{\"name\": \"Joe\")]
          |> to_extract_messages(),
          [~s(, \"age\": 21},{\"name\": \"Bobby\",\"age\": 62}), ~s(])] |> to_extract_messages(4)
        ]
      end

      context = Context.new() |> Context.set_source(source)
      {:ok, context} = Extract.Step.execute(%Extract.Decode.Json{}, context)

      expected = [
        [
          %{"name" => "Kyle", "age" => 2},
          %{"name" => "Joe", "age" => 21},
          %{"name" => "Bobby", "age" => 62}
        ]
        |> to_extract_messages(4)
      ]

      assert Context.get_stream(context) |> Enum.to_list() == expected
    end

    test "decodes a non-list stream to json" do
      source = fn _ ->
        [
          [
            ~s({"name": "Jay",),
            ~s("age": 42})
          ]
          |> to_extract_messages()
        ]
      end

      context = Context.new() |> Context.set_source(source)
      {:ok, context} = Extract.Step.execute(%Extract.Decode.Json{}, context)

      expected = [[%{"name" => "Jay", "age" => 42}] |> to_extract_messages(2)]
      assert Context.get_stream(context) |> Enum.to_list() == expected
    end
  end

  defp to_extract_messages(list, id \\ :not_set) do
    Enum.reduce(list, {0, []}, fn data, {i, buffer} ->
      meta_id =
        case id == :not_set do
          true -> i + 1
          false -> id
        end

      {i + 1, buffer ++ [Extract.Message.new(data: data, meta: %{"id" => meta_id})]}
    end)
    |> elem(1)
  end
end

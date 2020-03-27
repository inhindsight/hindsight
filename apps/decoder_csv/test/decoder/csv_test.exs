defmodule Decoder.CsvTest do
  use ExUnit.Case
  import Checkov

  describe "new/1" do
    data_test "validates #{inspect(field)} against bad input" do
      assert {:error, [%{input: value, path: [field]} | _]} =
               put_in(%{}, [field], value)
               |> Decoder.Csv.new()

      where([
        [:field, :value],
        [:version, "1"],
        [:headers, "a"],
        [:headers, nil],
        [:skip_first_line, "true"]
      ])
    end
  end

  test "can be decoded back into struct" do
    struct = Decoder.Csv.new!(headers: ["name"])
    json = Jason.encode!(struct)

    assert {:ok, struct} == Jason.decode!(json) |> Decoder.Csv.new()
  end

  test "brook serializer can serialize and deserialize" do
    struct = Decoder.Csv.new!(headers: ["name"])

    assert {:ok, struct} =
             Brook.Serializer.serialize(struct) |> elem(1) |> Brook.Deserializer.deserialize()
  end

  describe "Decoder" do
    test "parses context stream into csv" do
      decoder = Decoder.Csv.new!(
        headers: ["name", "age"],
        skip_first_line: false
      )

      input = [
        ["brian,21\n", "rick,34"],
        ["johnson,45\n", "greg,89"]
      ]

      output = Decoder.decode(decoder, input)

      assert Enum.to_list(output) ==
               [
                 [%{"name" => "brian", "age" => "21"}, %{"name" => "rick", "age" => "34"}],
                 [%{"name" => "johnson", "age" => "45"}, %{"name" => "greg", "age" => "89"}]
               ]
    end

    test "parses csv while skipping first line" do
      decoder = Decoder.Csv.new!(
        headers: ["name", "age"],
        skip_first_line: true
      )

      input = [
        ["brian,21\n", "rick,34"],
        ["johnson,45\n", "greg,89"]
      ]

      output = Decoder.decode(decoder, input)

      assert Enum.to_list(output) ==
               [
                 [%{"name" => "rick", "age" => "34"}],
                 [%{"name" => "johnson", "age" => "45"}, %{"name" => "greg", "age" => "89"}]
               ]
    end
  end
end

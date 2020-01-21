defmodule Extract.Decode.CsvTest do
  use ExUnit.Case
  import Checkov

  alias Extract.Steps.Context

  describe "new/1" do
    data_test "validates #{inspect(field)} against bad input" do
      assert {:error, [%{input: value, path: [field]} | _]} =
               put_in(%{}, [field], value)
               |> Extract.Decode.Csv.new()

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
    struct = Extract.Decode.Csv.new!(headers: ["name"])
    json = Jason.encode!(struct)

    assert {:ok, struct} == Jason.decode!(json) |> Extract.Decode.Csv.new()
  end

  test "brook serializer can serialize and deserialize" do
    struct = Extract.Decode.Csv.new!(headers: ["name"])

    assert {:ok, struct} =
      Brook.Serializer.serialize(struct) |> elem(1) |> Brook.Deserializer.deserialize()
  end

  describe "Extract.Step" do
    test "parses context stream into csv" do
      step = %Extract.Decode.Csv{
        headers: ["name", "age"],
        skip_first_line: false
      }

      source = fn _ -> ["brian,21\n", "rick,34", "johnson,45\n", "greg,89"] end
      context = Context.new() |> Context.set_source(source)

      {:ok, context} = Extract.Step.execute(step, context)

      stream = Context.get_stream(context) |> Enum.to_list()

      assert stream == [
               %{"name" => "brian", "age" => "21"},
               %{"name" => "rick", "age" => "34"},
               %{"name" => "johnson", "age" => "45"},
               %{"name" => "greg", "age" => "89"}
             ]
    end
  end
end

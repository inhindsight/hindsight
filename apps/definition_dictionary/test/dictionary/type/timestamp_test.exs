defmodule Dictionary.Type.TimestampTest do
  use ExUnit.Case
  import Checkov

  describe "new/1" do
    data_test "validates #{inspect(field)} against bad input" do
      assert {:error, [%{input: value, path: [field]} | _]} =
               put_in(%{}, [field], value)
               |> Dictionary.Type.Timestamp.new()

      where [
        [:field, :value],
        [:version, "1"],
        [:name, ""],
        [:name, nil],
        [:description, nil],
        [:format, ""],
        [:format, nil]
      ]
    end
  end

  test "can be encoded to json" do
    expected = %{
      "version" => 1,
      "name" => "name",
      "description" => "description",
      "format" => "%Y-%0m-%0d %0H:%0M:%0S",
      "type" => "timestamp"
    }

    assert expected ==
             Jason.encode!(%Dictionary.Type.Timestamp{
               name: "name",
               description: "description",
               format: "%Y-%0m-%0d %0H:%0M:%0S"
             })
             |> Jason.decode!()
  end

  test "can be decoded back into struct" do
    string = Dictionary.Type.Timestamp.new!(name: "name", description: "description", format: "%Y")
    json = Jason.encode!(string)

    assert {:ok, string} == Jason.decode!(json) |> Dictionary.Type.Timestamp.new()
  end

  test "brook serializer can serialize and deserialize" do
    string = Dictionary.Type.Timestamp.new!(name: "name", description: "description", format: "%Y")

    assert {:ok, string} =
             Brook.Serializer.serialize(string) |> elem(1) |> Brook.Deserializer.deserialize()
  end

  data_test "validates dates - #{inspect(value)} --> #{inspect(result)}" do
    field = Dictionary.Type.Timestamp.new!(name: "fake", format: format)
    assert result == Dictionary.Type.Normalizer.normalize(field, value)

    where [
      [:format, :value, :result],
      ["%Y-%0m-%0d %0H:%0M:%0S", "2020-01-01 08:31:12", {:ok, "2020-01-01T08:31:12"}],
      ["%0m-%0d-%Y %0S:%0M:%0H", "05-10-1989 12:21:07", {:ok, "1989-05-10T07:21:12"}],
      ["%Y", "1999-05-01", {:error, "Expected end of input at line 1, column 4"}],
      ["%Y", "", {:ok, ""}],
      ["%Y", nil, {:ok, ""}]
    ]
  end
end

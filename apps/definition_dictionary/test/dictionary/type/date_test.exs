defmodule Dictionary.Type.DateTest do
  use ExUnit.Case
  import Checkov

  describe "new/1" do
    data_test "validates #{inspect(field)} against bad input" do
      assert {:error, [%{input: value, path: [field]} | _]} =
               put_in(%{}, [field], value)
               |> Dictionary.Type.Date.new()

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
      "format" => "%Y-%0m-%0d",
      "type" => "date"
    }

    assert expected ==
             Jason.encode!(%Dictionary.Type.Date{
               name: "name",
               description: "description",
               format: "%Y-%0m-%0d"
             })
             |> Jason.decode!()
  end

  test "can be decoded back into struct" do
    string = Dictionary.Type.Date.new!(name: "name", description: "description", format: "%Y")
    json = Jason.encode!(string)

    assert {:ok, string} == Jason.decode!(json) |> Dictionary.Type.Date.new()
  end

  test "brook serializer can serialize and deserialize" do
    string = Dictionary.Type.Date.new!(name: "name", description: "description", format: "%Y")

    assert {:ok, string} =
             Brook.Serializer.serialize(string) |> elem(1) |> Brook.Deserializer.deserialize()
  end

  data_test "validates dates - #{inspect(value)} --> #{inspect(result)}" do
    field = Dictionary.Type.Date.new!(name: "fake", format: format)
    assert result == Dictionary.Type.Normalizer.normalize(field, value)

    where [
      [:format, :value, :result],
      ["%Y-%0m-%0d", "2020-01-01", {:ok, "2020-01-01"}],
      ["%0m-%0d-%Y", "05-10-1989", {:ok, "1989-05-10"}],
      ["%Y", "1999-05-01", {:error, "Expected end of input at line 1, column 4"}],
      ["%Y", "", {:ok, ""}],
      ["%Y", nil, {:ok, ""}]
    ]
  end
end

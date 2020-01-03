defmodule Dictionary.Type.StringTest do
  use ExUnit.Case
  import Checkov

  describe "new/1" do
    data_test "validates #{inspect(field)} against bad input" do
      assert {:error, [%{input: value, path: [field]} | _]} =
               put_in(%{}, [field], value)
               |> Dictionary.Type.String.new()

      where [
        [:field, :value],
        [:version, "1"],
        [:name, ""],
        [:name, nil],
        [:description, nil]
      ]
    end
  end

  describe "Dictionary.Type.Decoder.decode/2" do
    data_test "validates #{inspect(field)} against bad input" do
      assert {:error, [%{input: value, path: [field]} | _]} =
               put_in(%{}, [field], value)
               |> decode()

      where [
        [:field, :value],
        ["version", "1"],
        ["name", ""],
        ["name", nil],
        ["description", nil]
      ]
    end
  end

  test "can be encoded to json" do
    expected = %{
      "version" => 1,
      "name" => "name",
      "description" => "description",
      "type" => "string"
    }

    assert expected ==
             Jason.encode!(%Dictionary.Type.String{name: "name", description: "description"})
             |> Jason.decode!()
  end

  test "can be decoded back into struct" do
    map = %{
      "version" => 1,
      "name" => "name",
      "description" => "description",
      "type" => "string"
    }

    expected = {:ok, %Dictionary.Type.String{name: "name", description: "description"}}

    assert expected == Dictionary.Type.Decoder.decode(struct(Dictionary.Type.String), map)
  end

  defp decode(map) do
    Dictionary.Type.Decoder.decode(struct(Dictionary.Type.String), map)
  end
end

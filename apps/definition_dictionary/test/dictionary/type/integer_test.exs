defmodule Dictionary.Type.IntegerTest do
  use ExUnit.Case
  import Checkov

  describe "new/1" do
    data_test "validates #{inspect(field)} against bad input" do
      assert {:error, [%{input: value, path: [field]} | _]} =
               put_in(%{}, [field], value)
               |> Dictionary.Type.Integer.new()

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
      "type" => "integer"
    }

    assert expected ==
             Jason.encode!(%Dictionary.Type.Integer{name: "name", description: "description"})
             |> Jason.decode!()
  end

  test "can be decoded back into struct" do
    map = %{
      "version" => 1,
      "name" => "name",
      "description" => "description",
      "type" => "integer"
    }

    expected = {:ok, %Dictionary.Type.Integer{name: "name", description: "description"}}

    assert expected == Dictionary.Type.Decoder.decode(struct(Dictionary.Type.Integer), map)
  end

  data_test "validates integers -- #{inspect(value)} --> #{inspect(result)}" do
    assert result == Dictionary.Type.Normalizer.normalize(%Dictionary.Type.Integer{}, value)

    where [
      [:value, :result],
      [1, {:ok, 1}],
      ["123", {:ok, 123}],
      ["one", {:error, :invalid_integer}]
    ]
  end

  defp decode(map) do
    Dictionary.Type.Decoder.decode(struct(Dictionary.Type.Integer), map)
  end
end

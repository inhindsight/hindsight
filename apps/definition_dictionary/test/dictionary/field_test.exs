defmodule Dictionary.FieldTest do
  use ExUnit.Case
  import Checkov

  alias Dictionary.Field.InvalidChildFieldError

  describe "new/1" do
    data_test "validates #{field} against bad input" do
      assert {:error, [%{input: value, path: [field]} | _]} =
               put_in(%{}, [field], value)
               |> Dictionary.Field.new()

      where [
        [:field, :value],
        [:version, "1"],
        [:name, ""],
        [:name, nil],
        [:type, ""],
        [:type, nil],
        [:description, nil],
        [:fields, %{}]
      ]
    end

    test "validates child fields" do
      child1 = %{}
      child2 = %{version: 1, name: "name", type: "string"}
      child3 = %{version: 1, name: "age"}

      {:error, reason} =
        Dictionary.Field.new(
          version: 1,
          name: "name",
          type: "string",
          fields: [child1, child2, child3]
        )

      {:error, reason1} = Norm.conform(struct(Dictionary.Field, child1), Dictionary.Field.V1.s())
      {:error, reason3} = Norm.conform(struct(Dictionary.Field, child3), Dictionary.Field.V1.s())

      expected = [
        InvalidChildFieldError.exception(
          message: "Invalid child field",
          index: 0,
          errors: reason1
        ),
        InvalidChildFieldError.exception(
          message: "Invalid child field",
          index: 2,
          errors: reason3
        )
      ]

      assert expected == reason
    end
  end
end

defmodule Transform.AddTimestampFieldTest do
  use ExUnit.Case
  use Placebo

  describe "add timestamp transformation" do
    test "add field to dictionary" do
      input =
        Dictionary.from_list([
          Dictionary.Type.String.new!(name: "foo")
        ])

      field_name = "timestamp"
      step = Transform.AddTimestampField.new!(%{name: field_name, description: "bar"})
      path = Dictionary.Access.to_access_path(field_name)
      {:ok, output} = Transform.Step.transform_dictionary(step, input)

      assert %Dictionary.Type.Timestamp{name: field_name, description: "bar"} =
               get_in(output, path)
    end

    test "add value to record" do
      {:ok, now} = NaiveDateTime.new(2020, 5, 22, 11, 12, 0)
      now_string = NaiveDateTime.to_iso8601(now)
      allow(NaiveDateTime.to_iso8601(any()), return: now_string)
      input = %{foo: "bar"}
      transform = Transform.AddTimestampField.new!(name: "timestamp")
      {:ok, transform_function} = Transform.Step.create_function(transform, input)
      {:ok, new_value} = transform_function.(input)
      assert Map.get(new_value, "timestamp") == now_string
    end
  end
end

defmodule Transform.AddTimestampFieldTest do
  use ExUnit.Case
  use Placebo

  describe "add timestamp" do
    test "add timestamp field to dictionary" do
      input = Dictionary.from_list([
        Dictionary.Type.String.new!(name: "foo")
      ])
      field_name = "timestamp"
      step = Transform.AddTimestampField.new!(name: field_name)
      path = Dictionary.Access.to_access_path(field_name)
      {:ok, output} = Transform.Step.transform_dictionary(step, input)
      assert %Dictionary.Type.Timestamp{} = get_in(output, path)
    end

    test "add timestamp value to record" do
      now = 1511324473
      now_string = DateTime.from_unix!(now) |> DateTime.to_iso8601()
      allow(DateTime.to_iso8601(any()), return: now_string)
      input = %{foo: "bar"}
      transform = Transform.AddTimestampField.new!(name: "timestamp")
      {:ok, {:ok, transform_function}} = Transform.Step.create_function(transform, input)
      assert transform_function.(input) |> Map.get("timestamp") == now_string
    end
  end
end

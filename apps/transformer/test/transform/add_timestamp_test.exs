defmodule Transform.AddTimestampTest do
  use ExUnit.Case

  describe "add timestamp" do
    test "add timestamp field to dictionary" do
      input = Dictionary.from_list([
        Dictionary.Type.String.new!(name: "foo")
      ])
      field_name = "timestamp"
      step = Transform.AddTimestamp.new!(name: field_name)
      path = Dictionary.Access.to_access_path(field_name)
      {:ok, output} = Transform.Step.transform_dictionary(step, input)
      assert %Dictionary.Type.Timestamp{} = get_in(output, path)
    end

    test "add timestamp value to record"

  end
end

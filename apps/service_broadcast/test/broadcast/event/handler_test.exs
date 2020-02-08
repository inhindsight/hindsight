defmodule Broadcast.Event.HandlerTest do
  use ExUnit.Case

  import Events, only: [transform_define: 0]

  @instance Broadcast.Application.instance()

  describe "#{transform_define()}" do
    test "will store the transform definition in view state" do
      transform =
        Transform.new!(
          id: "transform-1",
          dataset_id: "dataset-1",
          subset_id: "sb1",
          dictionary: [
            Dictionary.Type.String.new!(name: "name"),
            Dictionary.Type.Integer.new!(name: "age")
          ],
          steps: [
            Transformer.MoveField.new!(from: "name", to: "fullname")
          ]
        )

      Brook.Test.send(@instance, transform_define(), "testing", transform)

      assert {:ok, transform} == Broadcast.Transformations.get("dataset-1")
    end
  end
end

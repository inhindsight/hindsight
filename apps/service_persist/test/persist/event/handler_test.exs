defmodule Persist.Event.HandlerTest do
  use ExUnit.Case

  @instance Persist.Application.instance()

  import Events, only: [transform_define: 0]

  test "persists transformation for dataset" do
    transform =
      Transform.new!(
        id: "transform-1",
        dataset_id: "ds1",
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

    assert {:ok, transform} == Persist.Transformations.get(transform.dataset_id, transform.subset_id)
  end
end

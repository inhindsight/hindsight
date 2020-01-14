defmodule PersistTest do
  use ExUnit.Case

  import Definition.Events

  @instance Persist.Application.instance()

  test "load:pesist:start starts writing to presto" do
    load =
      Load.Persist.new!(
        id: "persist-1",
        dataset: "ds1",
        name: "example",
        source: "topic-example",
        destination: "ds1_example",
        schema: [
          %Dictionary.Type.String{name: "name"},
          %Dictionary.Type.Integer{name: "age"}
        ]
      )

    send_load_persist_start(@instance, "testing", load)
  end
end

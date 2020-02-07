defmodule Load.PersistTest do
  use ExUnit.Case
  import Checkov

  describe "new/1" do
    data_test "validates #{field} against bad input" do
      input = put_in(%{}, [field], value)
      assert {:error, [%{input: value, path: [field]} | _]} = Load.Persist.new(input)

      where([
        [:field, :value],
        [:version, "1"],
        [:id, ""],
        [:id, nil],
        [:dataset_id, ""],
        [:dataset_id, nil],
        [:subset_id, ""],
        [:subset_id, nil],
        [:source, nil],
        [:source, ""],
        [:destination, nil],
        [:destination, ""]
      ])
    end

    test "will convert the schema back to structs" do
      persist =
        Load.Persist.new!(
          id: "load1",
          dataset_id: "ds1",
          subset_id: "joe",
          source: "topic",
          destination: "table",
          schema: [
            %Dictionary.Type.String{name: "name"},
            %Dictionary.Type.Integer{name: "age"}
          ]
        )

      json = Jason.encode!(persist)

      assert persist == Load.Persist.from_json(json) |> elem(1)
    end
  end
end

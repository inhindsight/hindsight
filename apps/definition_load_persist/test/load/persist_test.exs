defmodule Load.PersistTest do
  use ExUnit.Case

  describe "new/1" do
    test "will convert the schema back to structs" do
      persist =
        Load.Persist.new!(
          id: "load1",
          dataset_id: "ds1",
          subset_id: "joe",
          source: %Source.Fake{},
          destination: "table"
        )

      {:ok, serialized} = Brook.Serializer.serialize(persist)

      assert {:ok, persist} == Brook.Deserializer.deserialize(serialized)
    end
  end
end

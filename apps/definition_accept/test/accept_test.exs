defmodule AcceptTest do
  use ExUnit.Case
  use Placebo

  describe "new/1" do
    setup do
      fake_uuid = "123-456"
      allow(UUID.uuid4(), return: fake_uuid)

      input = %{
        version: 1,
        dataset_id: "123",
        subset_id: "456",
        destination: Destination.Fake.new!(),
        connection: FakeAcceptConnection.new!()
      }

      output = Map.merge(input, %{id: fake_uuid})
      [input: input, output: output]
    end

    test "accepts an input that contains an id", %{input: input} do
      input_with_id = Map.merge(input, %{id: "an id"})
      assert {:ok, _} = Accept.new(input_with_id)
    end

    test "accepts an input that does not contain an id", %{input: input} do
      assert {:ok, _} = Accept.new(input)
    end

    test "generates an id if not present", %{input: input, output: output} do
      assert {:ok, output} = Accept.new(input)
    end

    test "overwrites existing id with generated one", %{input: input, output: output} do
      input_with_id = Map.merge(input, %{id: "an id"})
      assert {:ok, output} = Accept.new(input_with_id)
    end
  end
end

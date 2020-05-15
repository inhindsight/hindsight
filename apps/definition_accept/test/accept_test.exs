defmodule AcceptTest do
  use ExUnit.Case
  use Placebo

  describe "new/1" do
    setup do
      fake_uuid = "123-456"
      allow(UUID.uuid4(), return: fake_uuid)
      fake_destination = Destination.Fake.new!()
      fake_connection = FakeAcceptConnection.new!()

      input = %{
        version: 1,
        dataset_id: "123",
        subset_id: "456",
        destination: fake_destination,
        connection: fake_connection
      }

      input_with_id = Map.put(input, :id, "an id")

      {:ok, accept_with_id} =
        Accept.new(
          version: 1,
          id: "an id",
          dataset_id: "123",
          subset_id: "456",
          destination: fake_destination,
          connection: fake_connection
        )

      {:ok, output} =
        Accept.new(
          version: 1,
          dataset_id: "123",
          subset_id: "456",
          destination: fake_destination,
          connection: fake_connection
        )

      [input: input, input_with_id: input_with_id, accept_with_id: accept_with_id, output: output]
    end

    test "accepts an input that contains an id", %{input_with_id: input_with_id} do
      assert {:ok, _} = Accept.new(input_with_id)
    end

    test "does not overwrite an id if one is present", %{
      input_with_id: input_with_id,
      accept_with_id: accept_with_id
    } do
      assert {:ok, ^accept_with_id} = Accept.new(input_with_id)
    end

    test "accepts an input that does not contain an id", %{input: input} do
      assert {:ok, _} = Accept.new(input)
    end

    test "generates an id if not present", %{input: input, output: output} do
      {:ok, ^output} = Accept.new(input)
    end
  end
end

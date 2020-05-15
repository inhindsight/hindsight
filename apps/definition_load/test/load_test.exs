defmodule LoadTest do
  use ExUnit.Case
  use Placebo

  describe "new/1" do
    setup do
      fake_uuid = "123-456"
      allow(UUID.uuid4(), return: fake_uuid)
      {:ok, [fake_uuid: fake_uuid]}
    end

    test "generates an id when none is present", %{fake_uuid: fake_uuid} do
      load_without_id = %{
        version: 1,
        dataset_id: "123",
        subset_id: "456",
        source: Source.Fake.new!(),
        destination: Destination.Fake.new!()
      }

      assert {:ok, observed} = Load.new(load_without_id)
      assert observed.id == fake_uuid
    end
  end
end

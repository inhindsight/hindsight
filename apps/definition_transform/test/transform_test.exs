defmodule TransformTest do
    use ExUnit.Case
    use Placebo

    describe "new/1" do
        setup do
            fake_uuid = "fake_uuid"
            allow(UUID.uuid4(), return: fake_uuid)
            {:ok, [fake_uuid: fake_uuid]}
        end

        test "generates an id when none is present", %{fake_uuid: fake_uuid} do
            transform_without_id = %{
                version: 1,
                dataset_id: "123",
                subset_id: "456",
            }

            assert {:ok, observed} = Transform.new(transform_without_id)
            assert observed.id == fake_uuid
        end
    end
end
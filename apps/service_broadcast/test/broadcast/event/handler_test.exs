defmodule Broadcast.Event.HandlerTest do
  use ExUnit.Case
  use Placebo
  import AssertAsync

  import Events, only: [transform_define: 0, dataset_delete: 0]

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
            Transform.MoveField.new!(from: "name", to: "fullname")
          ]
        )

      Brook.Test.send(@instance, transform_define(), "testing", transform)

      assert {:ok, transform} == Broadcast.Transformations.get("dataset-1", "sb1")
    end
  end

  describe "dataset_delete" do

    setup do
      Brook.Test.clear_view_state(@instance, "transformations")
      Brook.Test.clear_view_state(@instance, "streams")

      allow Broadcast.Stream.Supervisor.terminate_child(any()), return: :ok

      transform = Transform.new!(
        id: "transform-1",
        dataset_id: "ds1",
        subset_id: "sb1",
        dictionary: [],
        steps: []
      )

      load = Load.new!(
        id: "load-1",
        dataset_id: "ds1",
        subset_id: "sb1",
        source: Source.Fake.new!(),
        destination: Destination.Fake.new!()
      )

      Brook.Test.with_event(@instance, fn ->
        Broadcast.Transformations.persist(transform)
        Broadcast.Stream.Store.persist(load)
      end)

      delete = Delete.new!(
        id: "delete-1",
        dataset_id: "ds1",
        subset_id: "sb1"
      )

      Brook.Test.send(@instance, dataset_delete(), "testing", delete)

      [transform: transform, load: load, delete: delete]
    end

    test "deletes the transformation", %{load: load} do
      assert_async do
        assert {:ok, nil} == Broadcast.Transformations.get(load.dataset_id, load.subset_id)
      end
    end

    test "deletes the stream", %{load: load} do
      assert_async do
        assert nil == Broadcast.Stream.Store.get!(load.dataset_id, load.subset_id)
      end
    end

    test "stops the stream", %{load: load} do
      assert_async do
        assert_called Broadcast.Stream.Supervisor.terminate_child(load)
      end
    end

    test "deletes the source", %{load: %{source: source}} do
      assert_receive {:source_delete, ^source}
    end

    test "deletes the destination", %{load: %{destination: destination}} do
      assert_receive {:destination_delete, ^destination}
    end
  end
end

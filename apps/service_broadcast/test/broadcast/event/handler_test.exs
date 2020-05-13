defmodule Broadcast.Event.HandlerTest do
  use ExUnit.Case
  use Placebo
  import AssertAsync
  import Events, only: [transform_define: 0, dataset_delete: 0]
  import Definition, only: [identifier: 1]
  alias Broadcast.ViewState

  @instance Broadcast.Application.instance()

  setup do
    on_exit(fn ->
      [ViewState.Streams, ViewState.Transformations, ViewState.Sources, ViewState.Destinations]
      |> Enum.each(fn state -> Brook.Test.clear_view_state(@instance, state.collection()) end)
    end)

    :ok
  end

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

      assert {:ok, ^transform} =
               identifier(transform)
               |> Broadcast.ViewState.Transformations.get()
    end
  end

  describe "dataset_delete" do
    setup do
      allow(Broadcast.Stream.Supervisor.terminate_child(any()), return: :ok)

      transform =
        Transform.new!(
          id: "transform-1",
          dataset_id: "ds1",
          subset_id: "sb1",
          dictionary: [],
          steps: []
        )

      load =
        Load.new!(
          id: "load-1",
          dataset_id: "ds1",
          subset_id: "sb1",
          source: Source.Fake.new!(),
          destination: Destination.Fake.new!()
        )

      key = identifier(load)

      Brook.Test.with_event(@instance, fn ->
        ViewState.Transformations.persist(key, transform)
        ViewState.Streams.persist(key, load)
        ViewState.Sources.persist(key, load.source)
        ViewState.Destinations.persist(key, load.destination)
      end)

      delete =
        Delete.new!(
          id: "delete-1",
          dataset_id: "ds1",
          subset_id: "sb1"
        )

      Brook.Test.send(@instance, dataset_delete(), "testing", delete)

      [transform: transform, load: load, delete: delete, key: key]
    end

    test "deletes the transformation", %{key: key} do
      assert_async do
        assert {:ok, nil} = ViewState.Transformations.get(key)
      end
    end

    test "deletes the stream", %{key: key} do
      assert_async do
        assert {:ok, nil} = ViewState.Streams.get(key)
      end
    end

    test "stops the stream", %{load: load} do
      assert_async do
        assert_called(Broadcast.Stream.Supervisor.terminate_child(load))
      end
    end

    test "deletes the source", %{load: %{source: source}, key: key} do
      assert_receive {:source_delete, ^source}, 1_000
      assert {:ok, nil} = ViewState.Sources.get(key)
    end

    test "deletes the destination", %{load: %{destination: destination}, key: key} do
      assert_receive {:destination_delete, ^destination}
      assert {:ok, nil} = ViewState.Destinations.get(key)
    end
  end
end

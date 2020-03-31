defmodule Persist.LoaderTest do
  use ExUnit.Case
  require Temp.Env

  import Mox

  @instance Persist.Application.instance()

  Temp.Env.modify([
    %{
      app: :service_persist,
      key: Persist.Loader,
      set: [
        writer: Persist.WriterMock
      ]
    }
  ])

  setup :set_mox_global
  setup :verify_on_exit!

  setup do
    Process.flag(:trap_exit, true)
    Brook.Test.clear_view_state(@instance, "transformations")

    transform =
      Transform.new!(
        id: "transform-1",
        dataset_id: "ds1",
        subset_id: "fake-name",
        dictionary: [
          %Dictionary.Type.String{name: "name"},
          %Dictionary.Type.Integer{name: "age"}
        ],
        steps: []
      )

    Brook.Test.with_event(@instance, fn ->
      Persist.Transformations.persist(transform)
    end)

    load =
      Load.new!(
        id: "load-1",
        dataset_id: "ds1",
        subset_id: "fake-name",
        source: Source.Fake.new!(),
        destination: Destination.Fake.new!()
      )

    on_exit(fn ->
      Persist.Load.Supervisor.kill_all_children()
    end)

    [load: load, transform: transform]
  end

  describe "start destination" do
    test "will start destination", %{load: load} do
      start_supervised({Persist.Loader, load: load})

      assert_receive {:destination_start_link, _}, 1_000
    end

    test "will die if fails to start destination", %{load: load} do
      load = %{load | destination: Destination.Fake.new!(start_link: "failure")}
      assert {:error, "failure"} = Persist.Loader.start_link(load: load)
    end
  end

  describe "source" do
    test "will start source", %{load: load} do
      start_supervised({Persist.Loader, load: load})

      assert_receive {:source_start_link, source, context}
      assert context.dataset_id == load.dataset_id
      assert context.subset_id == load.subset_id
      assert context.assigns.destination == load.destination
    end
  end
end

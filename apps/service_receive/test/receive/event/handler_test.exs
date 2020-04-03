defmodule Receive.Event.HandlerTest do
  use ExUnit.Case
  use Placebo
  import AssertAsync

  import Events, only: [dataset_delete: 0]

  @instance Receive.Application.instance()

  describe "dataset_delete" do

    setup do
      Brook.Test.clear_view_state(@instance, "accepts")

      accept = Accept.new!(
        id: "accept-1",
        dataset_id: "ds1",
        subset_id: "sb1",
        destination: Destination.Fake.new!(),
        connection: Accept.Websocket.new!(
          path: "/",
          port: 8080
        )
      )

      [accept: accept]
    end

    test "something, something, deletes", %{accept: %{destination: destination} = accept} do
      allow Receive.Accept.Registry.whereis(:ds1__sb1_manager), return: :pid
      allow Receive.Accept.Supervisor.terminate_child(any()), return: :ok

      Brook.Test.with_event(@instance, fn ->
        Receive.Accept.Store.persist(accept)
      end)

      delete = Delete.new!(
        id: "delete-1",
        dataset_id: "ds1",
        subset_id: "sb1"
      )

      Brook.Test.send(@instance, dataset_delete(), "testing", delete)

      assert_async do
        assert nil == Receive.Accept.Store.get!(accept.dataset_id, accept.subset_id)
      end

      assert_called Receive.Accept.Supervisor.terminate_child(:pid)

      assert_receive {:destination_delete, ^destination}
    end
  end
end
